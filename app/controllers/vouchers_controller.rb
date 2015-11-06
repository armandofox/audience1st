class VouchersController < ApplicationController

  before_filter :is_logged_in
  before_filter :is_boxoffice_filter, :except => %w(update_shows reserve confirm_multiple confirm_reservation cancel_multiple cancel_reservation)
  before_filter :owns_voucher_or_is_boxoffice, :except => :update_shows

  private

  def owns_voucher_or_is_boxoffice
    @voucher = Voucher.find(params[:id]) if params[:id]
    @customer = Customer.find params[:customer_id]
    return if current_user.is_boxoffice
    redirect_with(customer_path(current_user), :alert => "That voucher isn't yours.") unless
      (current_user == @customer  && (@voucher.nil? || @voucher.customer == @customer))
  end

  def try_again(msg)
    flash[:notice] = msg
    redirect_to customer_path(@customer)
  end

  public

  # AJAX helper for addvoucher
  def update_shows
    @valid_vouchers = Vouchertype.find(params[:vouchertype_id]).valid_vouchers.sort_by(&:showdate)
    render :partial => 'reserve_for', :locals => {:valid_vouchers => @valid_vouchers}
  end

  def index
    @vouchers = @customer.vouchers.sort_by(&:reservation_status_then_showdate)
  end
  
  def new
    @page_title = "Add Comps"
    this_season = Time.this_season
    @vouchers = (
      Vouchertype.comp_vouchertypes(this_season + 1) +
      Vouchertype.comp_vouchertypes(this_season)).delete_if(&:external?)
    if @vouchers.empty?
      flash[:alert] = 'You must define some comp voucher types first.'
      redirect_to vouchertypes_path
      return
    end
    @valid_vouchers = @vouchers.first.valid_vouchers.sort_by(&:showdate)
  end

  def create
    # post: add the actual comps, and possibly reserve
    thenumtoadd = params[:howmany].to_i
    thevouchertype = Vouchertype.find(params[:vouchertype_id])
    thecomment = params[:comments].to_s
    theshowdate = Showdate.find_by_id(params[:showdate_id])

    flash[:alert] = 'Only comp vouchers can be added this way. For revenue vouchers,' <<
      'use the Buy Tickets purchase flow, and choose Check or Cash Payment.' unless
      thevouchertype.comp?
    flash[:alert] ||= 'Please select number of vouchers.' unless thenumtoadd > 0
    flash[:alert] ||= 'Please select a performance.' unless theshowdate
    flash[:alert] ||= 'This comp ticket type not valid for this performance.' unless
      vv = ValidVoucher.find_by_showdate_id_and_vouchertype_id(theshowdate.id,thevouchertype.id)
    
    redirect_to new_customer_voucher_path(@customer) and return if flash[:alert]

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
      RAILS_DEFAULT_LOGGER.error e.backtrace.inspect
    end
    
    redirect_to customer_path(@customer)
  end

  def update_comment
    @voucher.update_attributes(:comments => params[:comments], :processed_by => current_user)
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :voucher_id => @voucher.id,
      :comments => params[:comments],
      :logged_in_id => current_user.id)
    render :nothing => true
  end

  def reserve
    @is_admin = current_user.is_boxoffice
    redirect_with(customer_path(@customer), :alert => "Voucher #{@voucher.id} already reserved for #{@voucher.showdate.printable_name}") and return if @voucher.reserved?
    @valid_vouchers = @voucher.redeemable_showdates(@is_admin)
    @valid_vouchers = @valid_vouchers.select(&:visible?) unless @is_admin
    if @valid_vouchers.empty?
      flash[:notice] = "Sorry, but there are no shows for which this voucher can be reserved at this time.  This could be because all shows for which it's valid are sold out, because all seats allocated for this type of ticket may be sold out, or because seats allocated for this type of ticket may not be available for reservation until a future date."
      redirect_to customer_path(@customer)
    end
  end

  def confirm_multiple
    the_showdate = Showdate.find_by_id params[:showdate_id]
    try_again("Please select a date.") and return unless the_showdate
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
      flash[:notice] = "Your reservations could not be completed (#{errors})."
    when num
      flash[:notice] = "Your reservations are confirmed."
      email_confirmation(:confirm_reservation, @customer, the_showdate, count)
    else
      flash[:notice] = "Some of your reservations could not be completed: " <<
        errors <<
        "<br/>Please check the results below carefully before continuing."
      email_confirmation(:confirm_reservation, @customer, the_showdate, count)
    end
    redirect_to customer_path(@customer)
  end

  def confirm_reservation
    @voucher = Voucher.find(params[:id])
    @customer = @voucher.customer
    @is_admin = current_user.is_walkup
    try_again("Please select a date") and return if
      (showdate_id = params[:showdate_id].to_i).zero?
    the_showdate = Showdate.find(showdate_id)
    if @voucher.reserve_for(the_showdate, current_user, params[:comments])
      @voucher.save!
      flash[:notice] = "Reservation confirmed."
      if params[:email_confirmation] && @customer.valid_email_address?
        email_confirmation(:confirm_reservation, @customer, the_showdate, 1, @voucher.id)
      end
    else
      flash[:notice] = ["Sorry, can't complete this reservation: ", @voucher]
    end
    redirect_to customer_path(@customer)
  end

  def transfer_multiple
    vouchers = params[:vouchers].keys
    from_customer = Customer.find params[:customer_id]
    new_customer = Customer.find_by_id params[:customer]
    redirect_with(customer_vouchers_path(from_customer),
      :alert => 'Must select valid customer to transfer to.') and
      return unless new_customer.kind_of? Customer
  end

  def cancel_prepaid
    # A prepaid ticket can be cancelled at any time, but the voucher is
    # NOT reused.  it is "orphaned" and not linked to any customer or
    # show, but the record of its existence remains so that we can track
    # the fact that it was sold.  Its ID number will still be referred
    # to in the audit log.
    @v = Voucher.find(params[:id])
    @customer = @v.customer
    try_again("Please cancel this reservation before removing the voucher.") and return if @v.reserved?
    save_showdate = @v.showdate.id
    save_show = @v.showdate.show.id
    save_customer = @v.customer
    @v.showdate = nil
    @v.customer = nil
    @v.processed_by = @logged_in
    @v.save!
    Txn.add_audit_record(:txn_type => 'res_cancl',
                         :customer_id => save_customer.id,
                         :voucher_id => params[:id],
                         :logged_in_id => current_user.id,
                         :show_id => save_show,
                         :showdate => save_showdate,
                         :comment => 'Prepaid, comp or other nonsubscriber ticket')
    flash[:notice] = "Reservation cancelled, voucher unlinked from customer"
    redirect_to customer_path(save_customer)
  end

  def cancel_multiple
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
      else
        flash[:notice] << "Some reservations could NOT be cancelled. " <<
          "Please review your reservations below and contact a " <<
          "box office agent if you need assistance."
      end
    end
    flash[:notice] << "Your reservations have been cancelled. "
    flash[:notice] << "Your cancellation confirmation number is #{a}. " unless a.nil?
    email_confirmation(:cancel_reservation, @customer, old_showdate,
                       vchs.length, a) unless current_user.is_boxoffice
    redirect_to customer_path(@customer)
  end


  def cancel_reservation
    flash[:notice] ||= ""
    redirect_with(customer_path(@customer), :notice => "This reservation is not changeable") and return unless
      @voucher.can_be_changed?(current_user)
    redirect_with(customer_path(@customer), :alert => "This voucher is not currently reserved for any performance.") and return unless
      @voucher.reserved?
    showdate = @voucher.showdate
    old_showdate = showdate.clone
    showdate_id = showdate.id
    show_id = showdate.show.id
    if @voucher.cancel(current_user.id)
      a= Txn.add_audit_record(:txn_type => 'res_cancl',
        :customer_id => @customer.id,
        :logged_in_id => current_user.id,
        :showdate_id => showdate_id,
        :show_id => show_id,
        :voucher_id => @voucher.id)
      flash[:notice] = "Your reservation has been cancelled. " <<
        "Your cancellation confirmation number is #{a}. "
      email_confirmation(:cancel_reservation, @customer, old_showdate, 1, a) unless current_user.is_boxoffice
    else
      flash[:notice] = 'Error - reservation could not be cancelled'
    end
    redirect_to customer_path(@customer)
  end


end
