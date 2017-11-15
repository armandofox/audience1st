class VouchersController < ApplicationController

  before_filter :is_logged_in
  before_filter :is_boxoffice_filter, :except => %w(update_shows confirm_multiple cancel_multiple)
  before_filter :owns_voucher_or_is_boxoffice, :except => :update_shows

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
    @valid_vouchers = Vouchertype.find(params[:vouchertype_id]).valid_vouchers.sort_by(&:showdate)
    render :partial => 'reserve_for'
  end

  def index
    @vouchers = @customer.vouchers
  end

  def new
    @page_title = "Add Comps"
    this_season = Time.this_season
    @vouchers = (
      Vouchertype.comp_vouchertypes(this_season + 1) +
      Vouchertype.comp_vouchertypes(this_season)).delete_if(&:external?)
    if @vouchers.empty?
      redirect_to(vouchertypes_path, :alert => 'You must define some comp voucher types first.')
    end
    @valid_vouchers = []
    @email_disabled = @customer.email.blank?
  end

  def create
    # post: add the actual comps, and possibly reserve
    thenumtoadd = params[:howmany].to_i
    thevouchertype = Vouchertype.find_by_id(params[:vouchertype_id])
    thecomment = params[:comments].to_s
    theshowdate = Showdate.find_by_id(params[:showdate_id])
    shouldEmail = params[:customer_email]

    redir = new_customer_voucher_path(@customer)
    return redirect_to(redir, :alert => 'Please select number and type of vouchers to add.') unless
      thevouchertype && thenumtoadd > 0
    return redirect_to(redir, 'Only comp vouchers can be added this way. For revenue vouchers, use the Buy Tickets purchase flow, and choose Check or Cash Payment.') unless
      thevouchertype.comp?
    return redirect_to(redir, 'Please select a performance.') unless theshowdate
    return redirect_to(redir, 'This comp ticket type not valid for this performance.') unless
      vv = ValidVoucher.find_by_showdate_id_and_vouchertype_id(theshowdate.id,thevouchertype.id)

    order = Order.new_from_valid_voucher(vv, thenumtoadd,
      :comments => thecomment,
      :processed_by => current_user,
      :customer => @customer,
      :purchaser => @customer) # not a gift order

    begin
      order.finalize!
      order.vouchers.each do |v|
        Txn.add_audit_record(:txn_type => 'add_tkts',
          :order_id => order.id,
          :logged_in_id => current_user.id,
          :customer_id => @customer.id,
          :showdate_id => theshowdate.id,
          :voucher_id => v.id,
          :purchasemethod_id => Purchasemethod.get_type_by_name('none').id)
      end
      flash[:notice] = "Added #{thenumtoadd} '#{vv.name}' comps for #{theshowdate.printable_name}."
    rescue Order::NotReadyError => e
      flash[:alert] = ["Error adding comps: ", order]
    rescue RuntimeError => e
      flash[:alert] = "Unexpected error:<br/>#{e.message}"
      Rails.logger.error e.backtrace.inspect
    end
    if shouldEmail
      email_confirmation(:confirm_reservation, @customer, theshowdate, thenumtoadd)
    end
    redirect_to customer_path(@customer, :notice => flash[:notice])
  end

  def update_comment
    vchs = Voucher.find(params[:voucher_ids].split(","))
    vchs.each do |vchr|
      vchr.update_attributes(:comments => params[:comments], :processed_by => current_user)
    end
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :voucher_id => vchs.each.first,
      :comments => params[:comments],
      :logged_in_id => current_user.id)
    render :nothing => true

  end

  def reserve
    @is_admin = current_user.is_boxoffice
    redirect_to(customer_path(@customer), :alert => "Voucher #{@voucher.id} already reserved for #{@voucher.showdate.printable_name}") and return if @voucher.reserved?
    @valid_vouchers = @voucher.redeemable_showdates(@is_admin)
    @valid_vouchers = @valid_vouchers.select(&:visible?) unless @is_admin
    if @valid_vouchers.empty?
      flash[:alert] = "Sorry, but there are no shows for which this voucher can be reserved at this time.  This could be because all shows for which it's valid are sold out, because all seats allocated for this type of ticket may be sold out, or because seats allocated for this type of ticket may not be available for reservation until a future date."
      redirect_to customer_path(@customer)
    end
  end

  def confirm_multiple
    the_showdate = Showdate.find_by_id params[:showdate_id]
    redirect_to(customer_path(@customer), :alert => "Please select a date.") and return unless the_showdate
    num = params[:number].to_i
    count = 0
    vouchers = Voucher.find(params[:voucher_ids].split(",")).slice(0,num)
    errors = []
    comments = params[:comments].to_s
    vouchers.each do |v|
      if v.reserve_for(the_showdate, current_user, comments)
        count += 1
        comments = '' # only first voucher gets comment field
        Txn.add_audit_record(:txn_type => 'res_made',
          :customer_id => @customer.id,
          :voucher_id => v.id,
          :logged_in_id => current_user.id,
          :showdate_id => the_showdate.id,
          :comments => comments)
      else
        errors += v.errors.full_messages
      end
    end
    errors = errors.flatten.join ','
    case count
    when 0
      flash[:alert] = "Your reservations could not be completed (#{errors})."
    when num
      flash[:notice] = "Your reservations are confirmed."
      email_confirmation(:confirm_reservation, @customer, the_showdate, count)
    else
      flash[:alert] = "Some of your reservations could not be completed: " <<
        errors <<
        "<br/>Please check the results below carefully before continuing."
      email_confirmation(:confirm_reservation, @customer, the_showdate, count)
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
    canceled_num = 0
    num = params['cancelnumber'].to_i
    vchs = Voucher.find(params[:voucher_ids].split(","))
    old_showdate = vchs.first.showdate.clone
    a = nil
    flash[:notice] = ''
    vchs.each do |v|
      if v.can_be_changed?(current_user.id)
        showdate = v.showdate
        showdate_id = showdate.id
        show_id = showdate.show.id
        v.cancel(current_user.id)
        a = Txn.add_audit_record(:txn_type => 'res_cancl',
                                 :customer_id => @customer.id,
                                 :logged_in_id => current_user.id,
                                 :showdate_id => showdate_id,
                                 :show_id => show_id,
                                 :voucher_id => v.id)
        num -= 1
        canceled_num += 1
        break if num == 0
      else
        flash[:alert] << "Some reservations could NOT be cancelled. " <<
          "Please review your reservations below and contact a " <<
          "box office agent if you need assistance."
      end
    end
    flash[:notice] << "#{canceled_num} of your reservations have been cancelled. "
    flash[:notice] << "Your cancellation confirmation number is #{a}. " unless a.nil?
    email_confirmation(:cancel_reservation, @customer, old_showdate,
                       vchs.length, a) unless current_user.is_boxoffice
    redirect_to customer_path(@customer)
  end

end
