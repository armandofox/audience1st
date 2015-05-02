class StoreController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => %w(show_changed showdate_changed)

  before_filter :set_customer, :only => %w[index subscribe donate_to_fund]
  before_filter :is_logged_in, :only => %w[edit_billing_address checkout place_order]

  # flows:    ACTION                            INVARIANT
  #   index, subscribe, donate_to_fund    @customer is set
  #              |
  #         process_cart
  #        /             \
  #  shipping_address    |
  # set_shipping_address |
  #        \             /
  #    
  #  index          \
  #  donate_to_fund  +-- process_cart
  #  subscribe      / > process_cart -+--------> checkout--->place_order


  #                                   |              ^
  #                          shipping_addr -> set_shipping_addr
  def index

  private

  # invariant: after set_session_variables runs, the URL contains ID of customer doing the shopping
  def set_customer
    # logged_in?   desired   result
    # 1 nil          !anon    redirect to anonymous customer
    # 2 nil          anon     set customer=anon; no redirect
    # 3 non-admin    self     set customer=desired; no redirect
    # 4 non-admin    !=self   redirect with customer=logged-in
    # 5 admin        non-nil  set customer=desired; no redirect
    # 6 admin        nil,anon redirect with customer=
    logged_in = current_user()
    desired = Customer.find_by_id(params[:customer_id])
    # if URL is legal as-is, just proceed
    if well_formed_customer_url(logged_in, desired)
      @customer = desired
      @is_admin = current_admin.is_boxoffice
      @cart = find_cart
    else # must redirect to include a customer_id in the url
      desired = if !logged_in then Customer.anonymous_customer
                elsif logged_in.is_staff then desired || logged_in
                else logged_in
                end
      redirect_to params.merge(:customer_id => desired)
    end
  end

  def well_formed_customer_url(logged_in, desired)
    anon = Customer.anonymous_customer
    # we can proceed without a redirect if:
    return (desired == anon) if !logged_in
    staff_login = logged_in.is_boxoffice
    (staff_login && desired != anon) ||  ( ! staff_login && desired == logged_in )
  end

  public

  def index
    return_after_login :here
    @what = params[:what] || 'Regular Tickets'
    @page_title = "#{Option.venue} - Tickets"
    @special_shows_only = (@what =~ /special/i)
    reset_shopping unless (@promo_code = params[:promo_code])
    setup_for_showdate(showdate_from_params || showdate_from_show_params || showdate_from_default)
  end

      # All following actions can assume @customer is set. Doesn't mean that person is logged in,
      # but valid for eligibility for tickets
  def subscribe
    return_after_login :here
    @page_title = "#{Option.venue} - Subscriptions"
    @subscriber = @customer.subscriber?
    @next_season_subscriber = @customer.next_season_subscriber?
    reset_shopping unless @promo_code = params[:promo_code]
    # which subscriptions/bundles are available now?
    if @is_admin
      this_season = Time.this_season
      @subs_to_offer = ValidVoucher.bundles([this_season, this_season+1])
    else
      @subs_to_offer = ValidVoucher.bundles_available_to(@customer, @promo_code)
    end
    if @subs_to_offer.empty?
      flash[:alert] = "There are no subscriptions on sale at this time."
      redirect_to(:action => :index)
      return
    end
  end

  def donate_to_fund
    @account_code = AccountCode.find_by_id(params[:id])
    unless @account_code
      @account_code = AccountCode.find_by_code(params[:account_code]) ||
        AccountCode.default_account_code
      redirect_to :action => :donate_to_fund, :id => @account_code
    end
  end

  # This single action handles quick_donate: GET serves the form, POST places the order
  def donate
    @gCheckoutInProgress = nil                 # even if order in progress, going to donation page cancels it
    @customer =  (current_user() || Customer.new) and return if request.get?

    # If donor doesn't exist, create them and marked created-by-admin
    # If donor exists, make that the order's customer.
    # Create an order consisting of just a donation.

    @amount = params[:donation].to_i
    unless @amount > 0
      flash[:alert] = 'Donation amount must be provided'
      render(:action => 'donate') and return
    end
    @customer = Customer.for_donation(params[:customer])
    unless @customer.valid_as_purchaser?
      flash[:alert] = "Incomplete or invalid donor information: " + errors_as_html(@customer)
      render(:action => 'donate') and return
    end
    # Given valid donation, customer, and charge token, create & place credit card order.
    @order = Order.new_from_donation(@amount, AccountCode.default_account_code, @customer)
    @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
    @order.purchase_args = {:credit_card_token => params[:credit_card_token]}
    @order.processed_by = @customer
    @order.comments = params[:comments].to_s
    unless @order.ready_for_purchase?
      flash[:alert] = errors_as_html(@order)
      render(:action => 'donate') and return
    end
    if finalize_order(@order)
      render :action => 'place_order'
    else
      render :action => 'donate'
    end
  end

  def process_cart
    redirect_to_referer('Promo code activated.') and return if promo_code_provided
    @cart.add_comment params[:comments].to_s
    tickets = ValidVoucher.from_params(params[:valid_voucher])
    if @customer.is_boxoffice
      tickets.each_pair { |vv, qty| @cart.add_tickets(vv, qty) }
    else
      promo = params[:promo_code].to_s
      tickets.each_pair do |vv, qty|
        vv.customer = @customer
        @cart.add_with_checking(vv,qty,promo)
      end
    end
    redirect_to_referer(errors_as_html(@cart)) and return unless @cart.errors.empty?
    # all well with cart, try to process donation if any
    if params[:donation].to_i > 0
      @cart.add_donation(
        Donation.from_amount_and_account_code_id(params[:donation].to_i,
          params[:account_code_id] ))
    end
    redirect_to_referer('There is nothing in your order.') and return if @cart.cart_empty?
    if params[:gift] && @cart.include_vouchers?
      @recipient = session[:recipient_id] ? Customer.find_by_id(session[:recipient_id]) : Customer.new
      @mailable = @cart.has_mailable_items?
      remember_cart_in_session!
      redirect_to :action => 'shipping_address'
    else
      remember_cart_in_session!
      redirect_to_checkout
    end
  end

  def shipping_address
    set_checkout_in_progress true
    if request.get?
      #  collect gift recipient info
      @recipient = @cart.customer || Customer.new
      return
    end
    # request is a POST: collect shipping address
    # record whether we should mail to purchaser or recipient
    @cart.ship_to_purchaser = params[:ship_to_purchaser] if params[:mailable_gift_order]
    # if we can find a unique match for the customer AND our existing DB record
    #  has enough contact info, great.  OR, if the new record was already created but
    #  the buyer needs to modify it, great.
    #  Otherwise... create a NEW record based
    #  on the gift receipient information provided.
    recipient = recipient_from_session || recipient_from_params ||
      Customer.new(params[:customer])
    # make sure minimal info for gift receipient was specified.
    recipient.gift_recipient_only = true
    if recipient.new_record?
      recipient.created_by_admin = true if current_admin.is_boxoffice
      unless recipient.save
        flash[:alert] = recipient.errors.full_messages
        render :action => :shipping_address
        return
      end
    end
    @cart.customer = recipient
    @cart.save!
    redirect_to_checkout
  end

  def checkout
    return_after_login :here
    @sales_final_acknowledged = (params[:sales_final].to_i > 0) || current_admin.is_boxoffice
    @checkout_message =
      if @cart.include_regular_vouchers?
      then (Option.precheckout_popup ||
        "PLEASE DOUBLE CHECK DATES before submitting your order.  If they're not correct, you will be able to Cancel before placing the order.")
      else ""
      end
    @cart_contains_class_order = @cart.contains_enrollment?
    # if this is a "walkup web" sale (not logged in), nil out the
    # customer to avoid modifing the Walkup customer.
    redirect_to change_user_path and return unless logged_in?
    # here if valid user logged in
    @cart.processed_by ||= Customer.find(logged_in_id)
    @cart.purchaser ||= @customer
    @cart.customer ||= @cart.purchaser
    @cart.save!
  end

  def edit_billing_address
    return_after_login checkout_path(@customer)
    set_return_to :controller => 'store', :action => 'checkout'
    flash[:notice] = "Please update your credit card billing address below. Click 'Save Changes' when done to continue with your order."
    redirect_to :controller => 'customers', :action => 'edit'
  end

  def place_order
    @order = @cart
    @is_admin = current_admin.is_boxoffice
    # what payment type?
    @order.purchasemethod,@order.purchase_args = purchasemethod_from_params
    @recipient = @order.purchaser
    if ! @order.gift?
      # record 'who will pickup' field if necessary
      @order.add_comment(" - Pickup by: #{ActionController::Base.helpers.sanitize(params[:pickup])}") unless params[:pickup].blank?
    end
    unless @order.ready_for_purchase?
      flash[:alert] = errors_as_html(@order)
      redirect_to_checkout
      return
    end

    if finalize_order(@order)
      reset_shopping
      set_return_to
    else
      redirect_to_checkout
    end

  end


  # helpers for the AJAX handlers. These should probably be moved
  # to the respective models for shows and showdates, or called as
  # helpers from the views directly.

  def show_changed
    setup_for_showdate(showdate_from_show_params || showdate_from_default)
    render :partial => 'ticket_menus'
  end

  def showdate_changed
    setup_for_showdate(showdate_from_params || showdate_from_default)
    render :partial => 'ticket_menus'
  end

  private

  def finalize_order(order)
    success = false
    begin
      order.finalize!
      logger.error("SUCCESS purchase #{order.customer}; Cart summary: #{order.summary}")
      email_confirmation(:confirm_order, order.purchaser, order) if params[:email_confirmation]
      success = true
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError => e
      flash[:alert] = (order.errors.full_messages + [e.message]).join(', ')
      logger.error("FAILED purchase for #{order.customer}: #{order.errors.inspect}") rescue nil
    rescue Exception => e
      logger.error("Unexpected exception: #{e.message} #{e.backtrace}")
      flash[:alert] = "Sorry, an unexpected problem occurred with your order.  Please try your order again.  Message: #{e.message}"
    end
    success
  end

  def promo_code_provided
    @promo = params[:promo_code].to_s.strip.upcase
    params[:commit] == 'Redeem' && !@promo.blank?
  end

  def showdate_from_params
    Showdate.find_by_id(params[:showdate_id], :include => [:show, :valid_vouchers])
  end
  def showdate_from_show_params
    (s = Show.find_by_id(params[:show_id], :include => :showdates)) &&
      s.showdates.try(:first)
  end
  def showdate_from_default ; Showdate.current_or_next ; end

  def recipient_from_session
    if ((s = session[:recipient_id]) &&
        (recipient = Customer.find_by_id(s)))
      recipient.update_attributes(params[:customer])
      recipient
    else
      nil
    end
  end

  def recipient_from_params
    recipient = Customer.find_unique(Customer.new(params[:customer]))
    recipient && recipient.valid_as_gift_recipient? ? recipient : nil
  end

  def remember_cart_in_session!
    @cart.save!
    session[:cart] = @cart.id
  end

  def redirect_to_checkout
    redirect_to(:action => 'checkout',
      :sales_final => params[:sales_final],
      :email_confirmation => params[:email_confirmation])
    true
  end

  def redirect_to_referer(msg=nil)
    redirect_target =
      case params[:referer].to_s
      when 'donate' then quick_donate_path # no @customer assumed
      when 'donate_to_fund' then donate_to_fund_path(@customer, params[:account_code_id])
      when 'subscribe' then store_subscribe_path(@customer,:promo_code => @promo)
      when 'special' then store_special_path(@customer, :promo_code => @promo)
      else store_path(@customer,:promo_code => @promo)
      end
    flash[:alert] = msg
    redirect_to redirect_target
  end

  def purchasemethod_from_params
    if ( !@is_admin || params[:commit ] =~ /credit/i )
      meth = Purchasemethod.get_type_by_name(@cart.customer.try(:id) == logged_in_id ? 'web_cc' : 'box_cc')
      args = { :credit_card_token => params[:credit_card_token] }
    elsif params[:commit] =~ /check/i
      meth = Purchasemethod.get_type_by_name('box_chk')
      args = {:check_number => params[:check_number] }
    elsif params[:commit] =~ /cash/i
      meth = Purchasemethod.get_type_by_name('box_cash')
      args = {}
    else
      meth = nil
      args = {}
      flash[:alert] = "Invalid form of payment."
    end
    return meth,args
  end

  def setup_for_showdate(sd)
    @valid_vouchers = [] and return if sd.nil?
    @sd = sd
    @sh = @sd.show
    @special_shows_only = @sh.special?
    @all_showdates = @sh.showdates
    if @is_admin then setup_ticket_menus_for_admin else setup_ticket_menus_for_patron end
  end

  def setup_ticket_menus_for_admin
    @valid_vouchers = @sd.valid_vouchers.delete_if(&:comp?).map do |v|
      v.customer = @customer
      v.adjust_for_customer
    end.sort_by(&:display_order)
    @all_shows = Show.
      all_for_seasons(Time.this_season - 1, Time.this_season).
      special(@special_shows_only)  ||  []
    # ensure default show is included in list of shows
    @all_shows << @sh unless @all_shows.include? @sh
  end

  def setup_ticket_menus_for_patron
    @valid_vouchers = @sd.valid_vouchers.map do |v|
      v.customer = @customer
      v.adjust_for_customer @promo_code
    end.find_all(&:visible?).sort_by(&:display_order)
    @all_shows = Show.current_and_future.special(@special_shows_only) || []
    @all_shows << @sh unless @all_shows.include? @sh
  end

end
