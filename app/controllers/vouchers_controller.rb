class VouchersController < ApplicationController

  before_filter :is_logged_in
  before_filter(:is_boxoffice_filter,
                :only => %w[addvoucher process_addvoucher update_shows cancel_prepaid manage update_comment])
  before_filter(:owns_voucher_or_is_boxoffice,
                :only => %w[reserve confirm_reservation cancel_reservation])

  # AJAX helper for addvoucher
  def update_shows
    @valid_vouchers = Vouchertype.find(params[:vouchertype_id]).valid_vouchers.sort_by(&:showdate)
    render :partial => 'reserve_for', :locals => {:valid_vouchers => @valid_vouchers}
  end


  def addvoucher
    @page_title = "Add Comps"
    @customer = Customer.find params[:id]
    this_season = Time.this_season
    @vouchers = (
      Vouchertype.comp_vouchertypes(this_season + 1) +
      Vouchertype.comp_vouchertypes(this_season)).delete_if(&:external?)
    redirect_to({:controller => 'vouchertypes', :action => 'index'}, :notice => 'You must define some voucher types first.') and return if @vouchers.empty?
    @valid_vouchers = @vouchers.first.valid_vouchers.sort_by(&:showdate)
  end

  def process_addvoucher
    @customer = Customer.find params[:id]
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
    
    redirect_to(:action => 'addvoucher', :method => :get) and return if flash[:alert]

    order = Order.new_from_valid_voucher(vv, thenumtoadd,
      :comments => thecomment,
      :processed_by => @gLoggedIn,
      :customer => @customer,
      :purchaser => @customer) # not a gift order

    begin
      order.finalize!
      RAILS_DEFAULT_LOGGER.info "Txn: #{@gLoggedIn} issues #{@customer} #{thenumtoadd} '#{thevouchertype}' comps for #{theshowdate.printable_name}"
      flash[:notice] = "Added #{thenumtoadd} '#{vv.name}' comps for #{theshowdate.printable_name}."
    rescue Order::NotReadyError => e
      flash[:alert] = "Error adding comps:<br/> #{order.errors.full_messages.join(',')}"
    rescue RuntimeError => e
      flash[:alert] = "Unexpected error:<br/>#{e.message}"
      RAILS_DEFAULT_LOGGER.error e.backtrace.inspect
    end
    
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def update_comment
    who = logged_in_id rescue Customer.nobody_id
    if (voucher = Voucher.find_by_id(params[:vid]))
      voucher.update_attributes({:comments => params[:comments],
                                  :processed_by_id => who})
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => voucher.customer.id,
                           :voucher_id => voucher.id,
                           :comments => params[:comments],
                           :logged_in_id => logged_in_id)
    end
    render :nothing => true
  end

  def reserve
    @voucher = Voucher.find(params[:id]) # this is the voucher that customer wants to use
    @customer = @voucher.customer
    @is_admin = @gAdmin.is_boxoffice
    redirect_to(customer_path(@customer), :notice => "Voucher #{@voucher.id} already reserved for #{@voucher.showdate.printable_name}") and return if @voucher.reserved?
    @valid_vouchers = @voucher.redeemable_showdates(@is_admin)
    @valid_vouchers = @valid_vouchers.select(&:visible?) unless @is_admin
    if @valid_vouchers.empty?
      flash[:notice] = "Sorry, but there are no shows for which this voucher can be reserved at this time.  This could be because all shows for which it's valid are sold out, because all seats allocated for this type of ticket may be sold out, or because seats allocated for this type of ticket may not be available for reservation until a future date."
      redirect_to customer_path(@customer)
    end
  end

  def confirm_multiple
    showdate = params[:showdate_id].to_i
    try_again("Please select a date.") and return if showdate.zero?
    num = params[:number].to_i
    count = 0
    the_showdate = Showdate.find(showdate)
    vouchers = Voucher.find(params[:voucher_ids].split(",")).slice(0,num)
    errors = []
    comments = params[:comments].to_s
    customer = vouchers.first.customer
    vouchers.each do |v|
      if v.reserve_for(the_showdate, @gLoggedIn, comments)
        count += 1
        comments = '' # only first voucher gets comment field
        Txn.add_audit_record(:txn_type => 'res_made',
          :customer_id => customer.id,
          :voucher_id => v.id,
          :logged_in_id => logged_in_id,
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
      email_confirmation(:confirm_reservation, customer, showdate, count)
    else
      flash[:notice] = "Some of your reservations could not be completed: " <<
        errors <<
        "<br/>Please check the results below carefully before continuing."
      email_confirmation(:confirm_reservation, customer, showdate, count)
    end
    redirect_to customer_path(customer)
  end

  def confirm_reservation
    @voucher = Voucher.find(params[:id])
    @customer = @voucher.customer
    @is_admin = @gAdmin.is_walkup
    try_again("Please select a date") and return if
      (showdate_id = params[:showdate_id].to_i).zero?
    the_showdate = Showdate.find(showdate_id)
    if @voucher.reserve_for(the_showdate, @gLoggedIn, params[:comments])
      @voucher.save!
      flash[:notice] = "Reservation confirmed."
      if params[:email_confirmation] && @customer.valid_email_address?
        email_confirmation(:confirm_reservation, @customer, the_showdate, 1, @voucher.id)
      end
    else
      flash[:notice] = "Sorry, can't complete this reservation: #{@voucher.errors.full_messages.join(',')}"
    end
    redirect_to :controller => 'customers',:action => 'welcome',:id => @customer
  end

  def cancel_prepaid
    # A prepaid ticket can be cancelled at any time, but the voucher is
    # NOT reused.  it is "orphaned" and not linked to any customer or
    # show, but the record of its existence remains so that we can track
    # the fact that it was sold.  Its ID number will still be referred
    # to in the audit log.
    @v = Voucher.find(params[:id])
    try_again("Please cancel this reservation before removing the voucher.") and return if @v.reserved?
    save_showdate = @v.showdate.id
    save_show = @v.showdate.show.id
    save_customer = @v.customer
    @v.showdate = nil
    @v.customer = nil
    @v.processed_by_id = logged_in_id
    @v.save!
    Txn.add_audit_record(:txn_type => 'res_cancl',
                         :customer_id => save_customer.id,
                         :voucher_id => params[:id],
                         :logged_in_id => logged_in_id,
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
    customer = v.first.customer
    vchs.each do |v|
      if v.can_be_changed?(logged_in_id)
        showdate = v.showdate
        showdate_id = showdate.id
        show_id = showdate.show.id
        v.cancel(logged_in_id)
        a = Txn.add_audit_record(:txn_type => 'res_cancl',
                                 :customer_id => customer.id,
                                 :logged_in_id => logged_in_id,
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
    email_confirmation(:cancel_reservation, customer, old_showdate,
                       vchs.length, a) unless @gAdmin.is_boxoffice
    redirect_to customer_path(customer)
  end


  def cancel_reservation
    @v = Voucher.find(params[:id])
    flash[:notice] ||= ""
    unless @v.can_be_changed?(logged_in_id)
      flash[:notice] << "This reservation is not changeable"
      redirect_to(:controller => 'customers', :action => 'welcome')
      return
    end
    if !@v.reserved?
      flash[:notice] << "This voucher is not currently reserved for any performance."
      redirect_to(:controller => 'customers', :action => 'welcome')
      return
    end
    showdate = @v.showdate
    old_showdate = showdate.clone
    showdate_id = showdate.id
    show_id = showdate.show.id
    if @v.cancel(logged_in_id)
      a= Txn.add_audit_record(:txn_type => 'res_cancl',
        :customer_id => @v.customer.id,
        :logged_in_id => logged_in_id,
        :showdate_id => showdate_id,
        :show_id => show_id,
        :voucher_id => @v.id)
      flash[:notice] = "Your reservation has been cancelled. " <<
        "Your cancellation confirmation number is #{a}. "
      email_confirmation(:cancel_reservation, @v.customer, old_showdate, 1, a) unless @gAdmin.is_boxoffice
    else
      flash[:notice] = 'Error - reservation could not be cancelled'
    end
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  private

  def owns_voucher_or_is_boxoffice
    return true if is_walkup    # or higher
    return true if ((voucher = Voucher.find_by_id(params[:id])) &&
                    (voucher.customer == current_user))
    flash[:notice] = "Attempt to reserve a voucher that isn't yours."
    redirect_to logout_path
    return false
  end

  def try_again(msg)
    flash[:notice] = msg
    redirect_to :controller => 'customers', :action => 'welcome'
  end

end
