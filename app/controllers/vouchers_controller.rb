class VouchersController < ApplicationController

  before_filter :is_logged_in
  before_filter :is_boxoffice_filter, :except => %w(update_shows confirm_multiple cancel_multiple)
  before_filter :owns_voucher_or_is_boxoffice, :except => :update_shows

  ERR = 'reservations.errors.'  # prefix string for reservation error msgs in en.yml

  include VouchersHelper
  
  private

  def owns_voucher_or_is_boxoffice
    @voucher = Voucher.find(params[:id]) if params[:id]
    @customer = Customer.find params[:customer_id]
    return if current_user.is_boxoffice
    redirect_to(customer_path(current_user), :alert => "That voucher isn't yours.") unless
      (current_user == @customer  && (@voucher.nil? || @voucher.customer == @customer))
  end

  public

  # AJAX helper for adding comps
  def update_shows
    @valid_vouchers = ValidVoucher.
      where(:vouchertype_id => params[:vouchertype_id]).
      includes(:showdate => :show).
      order('showdates.thedate')
    # Vouchertype.find(params[:vouchertype_id]).valid_vouchers.sort_by(&:showdate)
    render :partial => 'reserve_for'
  end

  def index
    @vouchers = @customer.vouchers.
      includes(:showdate,:bundled_vouchers,:order => :purchaser)
  end

  def new
    @page_title = "Add Comps"
    this_season = Time.this_season
    @vouchers = (
      Vouchertype.comp_vouchertypes(this_season + 1) +
      Vouchertype.comp_vouchertypes(this_season)).delete_if(&:external?)
    return redirect_to(vouchertypes_path, :alert => t('season_setup.no_comps_defined')) if @vouchers.empty?
    @valid_vouchers = []
    @email_disabled = @customer.email.blank?
  end

  def create
    # post: add the actual comps, and possibly reserve
    seats = params[:seats].to_s.split(/\s*,\s*/)
    howmany = params[:howmany].to_i
    vouchertype = Vouchertype.find_by_id(params[:vouchertype_id])
    thecomment = params[:comments].to_s
    showdate = Showdate.find_by_id(params[:showdate_id])

    leave_open = params[:showdate_id].empty?

    redir = new_customer_voucher_path(@customer)
    return redirect_to(redir, :alert => 'Please select number and type of vouchers to add.') unless
      vouchertype && howmany > 0
    return redirect_to(redir, 'Only comp vouchers can be added this way. For revenue vouchers, use the Buy Tickets purchase flow, and choose Check or Cash Payment.') unless
      vouchertype.comp?
    return redirect_to(redir, 'Please select a performance.') unless showdate || leave_open

    if !leave_open
      vv = ValidVoucher.find_by(:showdate_id => showdate.id, :vouchertype_id => vouchertype.id) or
      return redirect_to(redir, 'This comp ticket type not valid for this performance.') 
    else 
      vv = ValidVoucher.find_by(:vouchertype_id => vouchertype.id)
    end
    
    order = Order.create(:comments => thecomment, :processed_by => current_user,
      :customer => @customer, :purchaser => @customer,
      :purchasemethod => Purchasemethod.get_type_by_name('none')) # not a gift order
    order.add_tickets_without_capacity_checks(vv, howmany, seats)
    begin
      order.finalize!
      order.vouchers.each do |v|
        if !leave_open
          Txn.add_audit_record(:txn_type => 'add_tkts',
          :order_id => order.id,
          :logged_in_id => current_user.id,
          :customer_id => @customer.id,
          :showdate_id => showdate.id,
          :voucher_id => v.id,
          :purchasemethod => Purchasemethod.get_type_by_name('none'))
          flash[:notice] = "Added #{howmany} '#{vv.name}' comps for #{showdate.printable_name}."
        else 
          Txn.add_audit_record(:txn_type => 'add_tkts',
          :order_id => order.id,
          :logged_in_id => current_user.id,
          :customer_id => @customer.id,
          :voucher_id => v.id,
          :purchasemethod => Purchasemethod.get_type_by_name('none'))
          Txn.add_audit_record(:txn_type => 'res_cancl',
            :customer_id => v.customer.id,
            :logged_in_id => current_user.id,
            :voucher_id => v.id)
          v.cancel(current_user)
          flash[:notice] = "Added #{howmany} '#{vv.name}' comps and customer can choose the show later."
        end
      end
    rescue Order::NotReadyError => e
      flash[:alert] = "Error adding comps: #{order.errors.as_html}".html_safe
      order.destroy
    rescue RuntimeError => e
      flash[:alert] = "Unexpected error:<br/>#{e.message}"
      Rails.logger.error e.backtrace.inspect
      order.destroy
    end
    email_confirmation(:confirm_reservation, @customer, showdate, order.vouchers) if params[:customer_email]
    redirect_to customer_path(@customer, :notice => flash[:notice])
  end


  def update_comment
    vchr = Voucher.find(params[:voucher_ids].split(",").first)
    vchr.update_attributes(:comments => params[:comments], :processed_by => current_user)
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :voucher_id => vchr.id,
      :comments => params[:comments],
      :logged_in_id => current_user.id)
    render :nothing => true

  end

  def confirm_multiple
    the_showdate = Showdate.find_by(:id => params[:showdate_id])
    num = params[:number].to_i
    return redirect_to(customer_path(@customer), :alert => t("#{ERR}no_showdate")) unless the_showdate
    return redirect_to(customer_path(@customer), :alert => t("#{ERR}no_vouchers")) unless num > 0
    vouchers = Voucher.find(params[:voucher_ids].split(",")).slice(0,num)
    if !params[:seats].blank?           # handle reserved seating reservation
      seats = params[:seats].split(/\s*,\s*/)
      return redirect_to(customer_path(@customer), :alert => t("#{ERR}seat_count_mismatch")) unless seats.length == vouchers.length
      vouchers.each { |v| v.seat = seats.pop }
    end
    comments = params[:comments].to_s
    Voucher.transaction do
      vouchers.each do |v|
        if v.reserve_for(the_showdate, current_user, comments)
          comments = '' # only first voucher gets comment field
          Txn.add_audit_record(:txn_type => 'res_made',
            :customer_id => @customer.id,
            :voucher_id => v.id,
            :logged_in_id => current_user.id,
            :showdate_id => the_showdate.id,
            :comments => comments)
        else
          raise Voucher::ReservationError
        end
      end
      email_confirmation(:confirm_reservation, @customer, the_showdate, vouchers)
    rescue Voucher::ReservationError, ActiveRecord::RecordInvalid => e
      flash[:alert] = t("#{ERR}reservation_failed", :message => errors_for_voucherlist_as_html(vouchers))
    end
    redirect_to customer_path(@customer)
  end

  def transfer_multiple
    vouchers = params[:vouchers]
    return redirect_to(customer_vouchers_path(@customer),
      :alert => 'Nothing was transferred because you did not select any vouchers.') unless vouchers
    cid = Customer.id_from_route(params[:cid]) # extract id from URL matching customer_path(params[:cid])
    new_customer = Customer.find_by_id(cid)
    return redirect_to(customer_vouchers_path(@customer),
      :alert => 'Nothing was transferred because you must select valid customer to transfer to.') unless new_customer.kind_of? Customer
    result,num_transferred = Voucher.transfer_multiple(vouchers.keys, new_customer, current_user)
    if result
      redirect_to customer_path(new_customer), :notice => "#{num_transferred} items transferred.  Now viewing #{new_customer.full_name}'s account."
    else
      redirect_to customer_transfer_multiple_vouchers_path(@customer), :alert => "NO changes were made because of error: #{msg}.  Try again."
    end
  end

  def cancel_multiple
    vchs = Voucher.includes(:showdate).find(params[:voucher_ids].split(","))
    return redirect_to(customer_path(@customer), :alert => t("#{ERR}cannot_be_changed"))unless
      vchs.all? { |v| v.can_be_changed?(current_user) }
    num = params['cancelnumber'].to_i
    orig_showdate = vchs.first.showdate
    orig_seats = Voucher.seats_for(vchs) # after cancel, seat info will be unavailable
    if (result = Voucher.cancel_multiple!(vchs, num, current_user))
      redirect_to customer_path(@customer), :notice => t('reservations.cancelled', :canceled_num => num)
      email_confirmation(:cancel_reservation, @customer, orig_showdate, orig_seats)
    else
      redirect_to customer_path(@customer), :alert => t('reservations.cannot_be_changed')
    end
  end

end
