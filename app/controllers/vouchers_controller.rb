class VouchersController < ApplicationController
  
  before_filter :is_logged_in
  before_filter :is_boxoffice_filter, :except => %w(update_shows confirm_multiple cancel_multiple)
  before_filter :owns_voucher_or_is_boxoffice, :except => :update_shows

  
  ERR = 'reservations.errors.'  # prefix string for reservation error msgs in en.yml

  private

  def owns_voucher_or_is_boxoffice
    @voucher = Voucher.find(params[:id]) if params[:id]
    @customer = Customer.find params[:customer_id]
    return if current_user.is_boxoffice
    redirect_to(customer_path(current_user), :alert => t("#{ERR}not_your_voucher")) unless
      (current_user == @customer  && (@voucher.nil? || @voucher.customer == @customer))
  end

  def errors_for_voucherlist_as_html(vouchers)
    vouchers.to_a.select { |item| !item.errors.empty? }.
      map { |item| item.errors.as_html }.
      join(', ')
  end

  public

  # AJAX helper for adding comps
  def update_shows
    @valid_vouchers = ValidVoucher.
      where(:vouchertype_id => params[:vouchertype_id]).
      includes(:showdate => :show).
      order('showdates.thedate')
    render :partial => 'reserve_comps_for'
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
    comp_order = params[:comp_order].merge({:seats => view_context.seats_from_params(params),
        :processed_by => current_user, :customer => @customer})

    add_comps_order = CompOrder.new(comp_order)

    if  !add_comps_order.valid?  ||  add_comps_order.finalize.nil?
      redirect_to new_customer_voucher_path(@customer), :alert => add_comps_order.errors.as_html
    else
      Txn.add_audit_record(:txn_type => 'add_tkts',
        :order_id => add_comps_order.order.id,
        :logged_in_id => current_user.id,
        :customer_id => @customer.id,
        :showdate_id => add_comps_order.showdate_id,
        :voucher_id => add_comps_order.order.vouchers.first.id,
        :purchasemethod => Purchasemethod.get_type_by_name('none'))
      if !add_comps_order.showdate_id.blank? && params[:customer_email]
        email_confirmation(:confirm_reservation, @customer, add_comps_order.showdate, add_comps_order.order.vouchers)
      end
      redirect_to customer_path(@customer), :notice => add_comps_order.confirmation_message
    end
  end

  def update_comment
    comment = params[:comments].to_s
    vouchers = Voucher.find(params[:voucher_ids].split(","))
    vouchers.each do |v|
      v.update_attributes(:comments => comment, :processed_by => current_user)
    end
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :voucher_id => vouchers.first.id,
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
      seats = seats_from_params(params)
      return redirect_to(customer_path(@customer), :alert => t("#{ERR}seat_count_mismatch")) unless seats.length == vouchers.length
      vouchers.each { |v| v.seat = seats.pop }
    end
    comments = params[:comments].to_s
    Voucher.transaction do
      vouchers.each do |v|
        if v.reserve_for(the_showdate, current_user, comments)
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
