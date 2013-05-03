class VouchersController < ApplicationController

  before_filter :is_logged_in
  before_filter(:is_boxoffice_filter,
                :only => %w[addvoucher update_shows remove_voucher cancel_prepaid manage update_comment])
  before_filter(:owns_voucher_or_is_boxoffice,
                :only => %w[reserve confirm_reservation cancel_reservation])

  verify(:method => :post,
         :only => %w[confirm_reservation cancel_reservation cancel_prepaid
                        remove_voucher],
         :add_to_flash => "System error: This operation must be a POST",
         :redirect_to => {:controller => 'customers', :action => 'welcome'})

  # AJAX helper for addvoucher
  def update_shows
    @available_seats = Showdate.current_and_future.map do |s|
      ValidVoucher.numseats_for_showdate_by_vouchertype(s,@gAdmin,Vouchertype.find(params[:vouchertype_id]), :redeeming => true,:ignore_cutoff => true)
    end
    render :partial => 'reserve_for', :locals => {:seats => @available_seats, :none => 'None (leave open)'}
  end


  def addvoucher
    @page_title = "Add Comps"
    unless (@customer = @gCustomer)
      flash[:notice] = "Must select a customer to add comps"
      redirect_to :controller => 'customers', :action => 'list'
      return
    end
    if request.get?
      @vouchers = Vouchertype.comp_vouchertypes(Time.this_season).reject { |v| v.offer_public == Vouchertype::EXTERNAL }
      if @vouchers.empty?
        flash[:notice] = "You must define some vouchertypes first"
        redirect_to(:controller => 'vouchertypes', :action => 'list')
      end
      @available_seats = Showdate.current_and_future.map do |s|
        ValidVoucher.numseats_for_showdate_by_vouchertype(s,@gAdmin, @vouchers.first,
          :redeeming => true, :ignore_cutoff => true)
      end
      return
    end
    # post: add the actual comps, and possibly reserve
    thenumtoadd = params[:howmany].to_i
    thevouchertype = params[:vouchertype_id].to_i
    thevouchername = (vt = Vouchertype.find(thevouchertype)).name
    thepurchasemethod = Purchasemethod.find_by_shortdesc('none')

    unless vt.comp?
      flash[:warning] = "Only comp vouchers can be added this way.  For revenue vouchers, use the Buy Tickets purchase flow, and choose Check or Cash Payment."
      redirect_to(:controller => 'customers', :action => 'welcome') and return
    end

    # if showdate specified, make sure allowed
    sd = nil
    if params[:showdate_id].to_i != 0
      unless (sd = Showdate.find_by_id(params[:showdate_id]))
        flash[:warning] = "No such performance."
        redirect_to(:action => 'addvoucher', :method => :get) and return
      end
      av = ValidVoucher.numseats_for_showdate_by_vouchertype(sd, @gAdmin, vt,
        :ignore_cutoff => true, :redeeming => true)
      unless av.howmany >= thenumtoadd
        flash[:warning] =
          "WARNING: You added #{thenumtoadd} comps, but only #{av.howmany} seats were left for this performance."
      end
    end

    thecomment = params[:comments] || ""
    custid = @customer.id
    begin
      Voucher.transaction do
        v = Array.new(thenumtoadd) do |i|
          vc = Voucher.new_from_vouchertype(thevouchertype,
            :purchasemethod_id => thepurchasemethod.id,
            :comments => thecomment,
            :processed_by_id => logged_in_id)
          @customer.vouchers << vc
          if sd
            vc.reserve_for(sd, logged_in_id, thecomment, :ignore_cutoff => true)
          end
          vc
        end
        if (v.kind_of?(Array) && !v.empty?)
          Txn.add_audit_record(:txn_type => 'add_tkts', :customer_id => custid,
            :voucher_id => v.first.id,
            :comments => thecomment,
            :logged_in_id => logged_in_id,
            :purchasemethod_id => thepurchasemethod)
          flash[:notice] = "#{thenumtoadd} of '#{vt.name}' successfully added"
          flash[:notice] << " and reserved for #{sd.printable_name}" if sd
        else
          flash[:notice] = "Adding comps FAILED: #{v}"
        end
      end
    rescue Exception => e
      flash[:notice] = "Error adding comps:<br/>#{e.message}"
    end
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def remove_voucher
    v = Voucher.find(params[:id])
    if v.nil?
      flash[:notice] = 'Voucher not found! Please logout and login again to re-sync.'
    else
      old_voucher_id = v.id
      old_cust_id = v.customer.id
      unless v.reserved?
        comment = ''
        v.destroy
        flash[:notice] = 'Voucher removed'
        Txn.add_audit_record(:txn_type => 'del_tkts',
                             :customer_id => @gCustomer.id,
                             :logged_in_id => logged_in_id,
                             :voucher_id => old_voucher_id,
                             :comments => comment)
      else
        flash[:notice] = 'Voucher not removed, must cancel reservation first'
      end
    end
    redirect_to :controller => 'customers', :action => 'welcome', :id => old_cust_id
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
    try_again("Voucher already used: #{@voucher.showdate.printable_name}") and return if @voucher.reserved?
    showdates = (@is_admin ?
                 Showdate.find(:all, :conditions => ["thedate >= ?", Time.now.at_beginning_of_season - 1.year]) :
                 Showdate.all_shows_this_season)
    @available_seats = showdates.map do |s|
      ValidVoucher.numseats_for_showdate_by_vouchertype(s,@customer,@voucher.vouchertype,:redeeming => true,:ignore_cutoff => @is_admin)
    end.reject { |av| av.howmany.zero? }
  end

  def confirm_multiple
    @is_admin = @gAdmin.is_walkup # really need to do this?? not in prefilter??
    @customer = @gCustomer
    try_again("Please select a date.") and return if
      (showdate = params[:showdate_id].to_i).zero?
    num = params[:number].to_i
    count = 0
    lasterr = 'errors occurred making reservations'
    the_showdate = Showdate.find(showdate)
    Voucher.find(params[:voucher_ids].split(",")).slice(0,num).each do |v|
      if v.reserve_for(the_showdate, logged_in_id, params[:comments].to_s, :ignore_cutoff => @is_admin)
        count += 1
        params[:comments] = nil # only first voucher gets comment field
      else
        lasterr = v.comments
      end
    end
    case count
    when 0
      flash[:notice] = "Your reservations could not be completed (#{lasterr})."
    when num
      flash[:notice] = "Your reservations are confirmed."
      email_confirmation(:confirm_reservation, @customer, showdate, count)
    else
      flash[:notice] = "Some of your reservations could not be completed " <<
        "(#{lasterr}).  Please check the results below carefully before " <<
        "continuing."
      email_confirmation(:confirm_reservation, @customer, showdate, count)
    end
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def confirm_reservation
    @voucher = Voucher.find(params[:id])
    @customer = @voucher.customer
    @is_admin = @gAdmin.is_walkup
    try_again("Please select a date") and return if
      (showdate = params[:showdate_id].to_i).zero?
    the_showdate = Showdate.find(showdate_id)
    if (a = @voucher.reserve_for(the_showdate, logged_in_id,
                                 params[:comments], :ignore_cutoff => @is_admin))
      flash[:notice] = "Reservation confirmed. " <<
        "Your confirmation number is #{a}."
      if params[:email_confirmation] && @customer.valid_email_address?
        email_confirmation(:confirm_reservation, @customer, showdate, 1, a)
      end
    else
      flash[:notice] = "Sorry, can't complete this reservation: #{@voucher.comments}"
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
    save_customer = @v.customer.id
    @v.showdate = nil
    @v.customer = nil
    @v.processed_by_id = logged_in_id
    @v.save!
    Txn.add_audit_record(:txn_type => 'res_cancl',
                         :customer_id => @gCustomer.id,
                         :voucher_id => params[:id],
                         :logged_in_id => logged_in_id,
                         :show_id => save_show,
                         :showdate => save_showdate,
                         :comment => 'Prepaid, comp or other nonsubscriber ticket')
    flash[:notice] = "Reservation cancelled, voucher unlinked from customer"
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def cancel_multiple
    vchs = Voucher.find(params[:voucher_ids].split(","))
    old_showdate = vchs.first.showdate.clone
    a = nil
    flash[:notice] = ''
    vchs.each do |v|
      if v.can_be_changed?(logged_in_id)
        showdate = v.showdate
        showdate_id = showdate.id
        show_id = showdate.show.id
        v.cancel(logged_in_id)
        a = Txn.add_audit_record(:txn_type => 'res_cancl',
                                 :customer_id => @gCustomer.id,
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
    email_confirmation(:cancel_reservation, @gCustomer, old_showdate,
                       vchs.length, a)
    redirect_to :controller => 'customers', :action => 'welcome'
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
        :customer_id => @gCustomer.id,
        :logged_in_id => logged_in_id,
        :showdate_id => showdate_id,
        :show_id => show_id,
        :voucher_id => @v.id)
      flash[:notice] = "Your reservation has been cancelled. " <<
        "Your cancellation confirmation number is #{a}. "
      email_confirmation(:cancel_reservation, @gCustomer, old_showdate, 1, a)
    else
      flash[:notice] = 'Error - reservation could not be cancelled'
    end
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def manage
    if request.get?
      if params[:vouchers]
        @vouchers = Voucher.find(params[:vouchers].split(','), :order => 'sold_on DESC')
      elsif params[:customer]
        @vouchers = Customer.find(params[:customer]).vouchers
      end
      if @vouchers.empty?
        flash[:notice] = "No vouchers selected."
        redirect_to :controller => 'customers', :action => 'welcome'
      end
      return
    end
    # post: transfer vouchers
    @ids = (params[:vouchers].sort) rescue nil
    if (@ids.nil? || @ids.empty?)
      flash[:notice] = "No vouchers were selected."
      redirect_to(:controller => 'customers', :action => 'welcome') and return
    end
    @vouchers = @ids.map { |v| Voucher.find_by_id(v) }.reject { |v| v.nil? }
    case params[:commit]
    when /transfer/i
      unless (recipient = Customer.find_by_id(params[:xfer_id]))
        flash[:notice] = "Recipient isn't in customer list. Please create an account for recipient first."
        redirect_to(:controller => 'customers', :action => 'new') and return
      end
      Voucher.transaction do
        @vouchers.each do |v|
          v.transfer_to_customer(recipient)
          Txn.add_audit_record(:txn_type => 'del_tkts',
            :customer_id => v.customer.id,
            :logged_in_id => logged_in_id,
            :purchasemethod_id => Purchasemethod.find_by_shortdesc('none'),
            :voucher_id => v.id)
          Txn.add_audit_record(:txn_type => 'add_tkts',
            :customer_id => recipient.id,
            :voucher_id => v.id,
            :logged_in_id => logged_in_id,
            :purchasemethod_id => Purchasemethod.find_by_shortdesc('none')
            )
        end
      end
      flash[:notice] = "Vouchers #{@ids.join(',')} were transferred to #{recipient.full_name}'s account."
    when /destroy/i
      Voucher.transaction do
        @vouchers.each do |v|
          v.freeze
          v.destroy
          Txn.add_audit_record(:txn_type => 'del_tkts',
            :customer_id => v.customer_id,
            :voucher_id => v.id,
            :logged_in_id => logged_in_id)
        end
      end
      flash[:notice] = "Vouchers #{@ids.join(',')} were deleted permanently."
    else
      flash[:notice] = "Sorry, this function isn't implemented yet."
    end
    redirect_to :controller => 'customers', :action => 'welcome'
  end

  def owns_voucher_or_is_boxoffice
    return true if is_walkup    # or higher
    return true if (params[:id] &&
                    (voucher = Voucher.find(params[:id].to_i)) &&
                    (voucher.customer.id == @gCustomer.id)) rescue nil
    flash[:notice] = "Attempt to reserve a voucher that isn't yours."
    redirect_to logout_path
    return false
  end

  private

  def try_again(msg)
    flash[:notice] = msg
    redirect_to :controller => 'customers', :action => 'welcome'
  end

end
