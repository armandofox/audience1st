class StoreController < ApplicationController

  include StoreHelper

  skip_before_filter :verify_authenticity_token, :only => %w(show_changed showdate_changed)

  before_filter :set_customer, :except => %w[donate]
  before_filter :is_logged_in, :only => %w[checkout place_order]

  #        ACTION                      INVARIANT BEFORE ACTION
  #        ------                      -----------------------
  # index, subscribe, donate_to_fund    valid @customer
  #              |
  #         process_cart
  #         /          \
  # shipping_address   |
  #         \          /
  #           checkout                logged in && valid @customer
  #               |
  #          place_order
  #===================================
  #             donate
  #               |
  #           place_order

  private

  # invariant: after set_customer runs, the URL contains ID of customer doing the shopping
  def set_customer
    logged_in = current_user()
    desired = Customer.find_by_id(params[:customer_id])
    # OK to proceed given this URL?
    if well_formed_customer_url(logged_in, desired)
      @customer = desired
      @is_admin = is_boxoffice()
      @cart = find_cart
    else # must redirect to include a customer_id in the url
      desired = if !logged_in then Customer.anonymous_customer
                elsif logged_in.is_staff then desired || logged_in
                else logged_in
                end
      p = params.to_hash
      redirect_to p.merge(:customer_id => desired, :only_path => true)
    end
  end

  def well_formed_customer_url(logged_in, desired)
    anon = Customer.anonymous_customer
    # we can proceed without a redirect if:
    return (desired == anon) if !logged_in # not logged in, & anonymous customer specified
    staff_login = logged_in.is_boxoffice
    (staff_login && desired && desired != anon) || # staff login, and any non-anon customer specified
      ( ! staff_login && desired == logged_in) # or regular login, and self specified
  end

  public

  # cancel the order, empty the cart, etc, and start fresh.
  def cancel
    reset_shopping
    if session[:guest_checkout]
      logout_keeping_session!
    end
    redirect_to store_path
  end

  def index
    return_after_login params.except(:customer_id)
    @logged_in = current_user()  
    @valid_vouchers = []
    @all_shows = []
    @all_showdates = []
    @show_url = url_for(params.except(:showdate_id).merge(:show_id => 'XXXX', :only_path => true)) # will be used by javascript to construct URLs
    @showdate_url = url_for(params.except(:show_id).merge(:showdate_id => 'XXXX', :only_path => true)) # will be used by javascript to construct URLs
    @reload_url = url_for(params.merge(:promo_code => 'XXXX', :only_path => true))
    @what = Show.type(params[:what])
    redirect_to store_subscribe_path(@customer) and return if @what == 'Subscription'
    @page_title = "#{Option.venue} - Tickets"
    reset_shopping unless (@promo_code = params[:promo_code])
    setup_for_showdate(showdate_from_params || showdate_from_show_params || showdate_from_default)
  end

  # All following actions can assume @customer is set. Doesn't mean that person is logged in,
  # but valid for eligibility for tickets
  def subscribe
    return_after_login params.except(:customer_id)
    @nobody_really_logged_in = (current_user().nil?)
    @page_title = "#{Option.venue} - Subscriptions"
    @reload_url = url_for(params.merge(:promo_code => 'XXXX'))
    @subscriber = @customer.subscriber?
    @what = 'Subscription'
    @next_season_subscriber = @customer.next_season_subscriber?
    reset_shopping unless @promo_code = params[:promo_code]
    # which subscriptions/bundles are available now?
    if @is_admin
      this_season = Time.this_season
      @subs_to_offer = ValidVoucher.bundles([this_season, this_season+1])
    else
      @subs_to_offer = ValidVoucher.bundles_available_to(@customer, @promo_code)
    end
    redirect_to(store_path(@customer), :alert => "There are no subscriptions on sale at this time.") if @subs_to_offer.empty?
  end

  def donate_to_fund
    return_after_login params.except(:customer_id)
    @account_code = AccountCode.find_by_code(params[:id]) ||
      AccountCode.find_by_id(params[:id]) ||
      AccountCode.default_account_code
  end

  # This single action handles quick_donate: GET serves the form, POST places the order
  def donate
    reset_shopping                 # even if order in progress, going to donation page cancels it
    unless (@customer = current_user)
      # handle donation as a 'guest checkout', even though may end up being tied to real customer
      @customer = Customer.new
      session[:guest_checkout] = true
    end
    return if request.get?

    # If donor doesn't exist, create them and marked created-by-admin
    # If donor exists, make that the order's customer.
    # Create an order consisting of just a donation.

    @amount = to_numeric(params[:donation])
    unless @amount > 0
      flash[:alert] = 'Donation amount must be provided'
      render(:action => 'donate') and return
    end
    @customer = Customer.for_donation(params[:customer])
    unless @customer.valid_as_purchaser?
      flash[:alert] = ["Incomplete or invalid donor information: ", @customer.errors.as_html]
      render(:action => 'donate') and return
    end
    # Given valid donation, customer, and charge token, create & place credit card order.
    @order = Order.new_from_donation(@amount, AccountCode.default_account_code, @customer)
    @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
    @order.purchase_args = {:credit_card_token => params[:credit_card_token]}
    @order.processed_by = @customer
    @order.comments = params[:comments].to_s
    unless @order.ready_for_purchase?
      flash[:alert] = @order.errors.as_html
      @customer =  (current_user() || Customer.new)
      render(:action => 'donate') and return
    end
    if finalize_order(@order)
      # forget customer after successful guest checkout
      @guest_checkout = true
      logout_keeping_session!
      render :action => 'place_order'
    else
      @customer =  (current_user() || Customer.new)
      render :action => 'donate'
    end
  end

  def process_cart
    @cart.add_comment params[:comments].to_s
    add_tickets_to_cart
    redirect_to_referer(@cart.errors.full_messages) and return unless @cart.errors.empty?
    add_retail_items_to_cart
    redirect_to_referer(@cart.errors.full_messages) and return unless @cart.errors.empty?
    # all well with cart, try to process donation if any
    add_donation_to_cart
    redirect_to_referer('There is nothing in your order.') and return if @cart.cart_empty?
    # order looks OK; all subsequent actions should display in-progress order at top of page
    add_service_charge_to_cart
    remember_cart_in_session!
    set_checkout_in_progress true
    # if gift, first collect separate shipping address...
    if params[:gift] && @cart.includes_vouchers?
      redirect_to shipping_address_path(@customer)
    else
      # otherwise go directly to checkout
      return_after_login params.except(:customer_id).merge(:action => 'checkout')
      redirect_to_checkout
    end
  end

  def shipping_address
    @mailable = @cart.includes_mailable_items?
    @recipient = Customer.new and return if request.get?
    # request is a POST: collect shipping address
    # record whether we should mail to purchaser or recipient
    @cart.ship_to_purchaser = params[:ship_to_purchaser] if params[:mailable_gift_order]
    # if we can find a unique match for the customer AND our existing DB record
    #  has enough contact info, great.  OR, if the new record was already created but
    #  the buyer needs to modify it, great.
    #  Otherwise... create a NEW record based
    #  on the gift receipient information provided.
    recipient = recipient_from_params
    @recipient =  recipient[0]
    if @recipient.email == @customer.email
      flash.now[:alert] = I18n.t('store.errors.gift_diff_email_notice') 
      render :action => :shipping_address
      return
    end 
    if email_matches_diff_last_name?
        flash.now[:alert] = I18n.t('store.errors.gift_matching_email_diff_last_name')
        render :action => :shipping_address
        return
    end
    # make sure minimal info for gift receipient was specified.
    @recipient.gift_recipient_only = true
    unless @recipient.valid?
      flash.now[:alert] = @recipient.errors.as_html
      render :action => :shipping_address
      return
    end
    @recipient.created_by_admin = @is_admin if @recipient.new_record?
    @recipient.save!
    @cart.customer = @recipient
    @cart.save!
    redirect_to_checkout
  end

  # Beyond this point, purchaser is logged in (or admin is logged in and acting on behalf of purchaser)

  def checkout
    redirect_to store_path, :alert => t('store.errors.empty_order') if @cart.cart_empty?
    @page_title = "Review Order For #{@customer.full_name}"
    @sales_final_acknowledged = @is_admin || (params[:sales_final].to_i > 0)
    @checkout_message = (@cart.includes_regular_vouchers? ? Option.precheckout_popup : '')
    @cart_contains_class_order = @cart.includes_enrollment?
    @allow_pickup_by_other = (@cart.includes_vouchers? && !@cart.gift?)
    @cart.processed_by ||= current_user()
    @cart.purchaser ||= @customer
    @cart.customer ||= @cart.purchaser
    @cart.save!
  end

  def place_order
    @page_title = "Confirmation of Order #{@cart.id}"
    @order = @cart
    # what payment type?
    @order.purchasemethod,@order.purchase_args = purchasemethod_from_params
    @recipient = @order.customer
    if ! @order.gift?
      # record 'who will pickup' field if necessary
      @order.add_comment(" - Pickup by: #{ActionController::Base.helpers.sanitize(params[:pickup])}") unless params[:pickup].blank?
    end
    @order.purchaser.update_attributes(params[:customer])
    unless @order.ready_for_purchase?
      flash[:alert] = @order.errors.as_html
      redirect_to_checkout
      return
    end

    if finalize_order(@order)
      reset_shopping
      if session[:guest_checkout]
        # forget customer after successful guest checkout
        logout_keeping_session!
        @guest_checkout = true
      end
    else
      redirect_to_checkout
    end

  end

  private

  def finalize_order(order)
    success = false
    begin
      order.finalize!
      Rails.logger.error("SUCCESS purchase #{order.customer}; Cart summary: #{order.summary}")
      email_confirmation(:confirm_order,order.purchaser,order) if params[:email_confirmation]
      success = true
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError => e
      flash[:alert] = order.errors.full_messages
      Rails.logger.error("FAILED purchase for #{order.customer}: #{order.errors.inspect}") rescue nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error: #{e.message} #{e.backtrace}")
      flash[:alert] = "Sorry, an unexpected problem occurred with your order.  Please try your order again.  Message: #{e.message}"
    end
    success
  end

  def showdate_from_params
    Showdate.includes(:valid_vouchers).find_by_id(params[:showdate_id])
  end
  def showdate_from_show_params
    (s = Show.find_by_id(params[:show_id])) &&
      (s.next_showdate || s.showdates.first)
  end
  def showdate_from_default ; Showdate.current_or_next(:type => @what) ; end
  def email_matches_diff_last_name?
    try_customer = Customer.new(params[:customer])
    Customer.email_matches_diff_last_name?(try_customer)
  end
  def recipient_from_params
    try_customer = Customer.new(params[:customer])
    recipient = Customer.find_unique(try_customer)
    (recipient && recipient.valid_as_gift_recipient?) ? [recipient,"found_matching_customer"] : [try_customer, "new_customer"]
  end
  def email_last_name_match_diff_address?
    try_customer = Customer.new(params[:customer])
    Customer.email_last_name_match_diff_address?(try_customer)
  end
  def remember_cart_in_session!
    @cart.save!
    session[:cart] = @cart.id
  end

  def redirect_to_checkout
    checkout_params = {}
    checkout_params[:sales_final] = true if params[:sales_final]
    checkout_params[:email_confirmation] = true if params[:email_confirmation]
    matching = recipient_from_params[1]
    if email_last_name_match_diff_address?
        flash[:notice] = I18n.t('store.gift_matching_email_last_name_diff_address')
    elsif matching == "found_matching_customer"
        flash[:notice] = I18n.t('store.gift_recipient_on_file')  
    end
    redirect_to checkout_path(@customer, checkout_params)
    true
  end

  def redirect_to_referer(msg=nil)
    promo_code_args = (@promo.blank? ? {} : {:promo_code => @promo})
    redirect_target =
      case params[:referer].to_s
      when 'donate' then quick_donate_path # no @customer assumed
      when 'donate_to_fund' then donate_to_fund_path(params[:account_code_id], @customer)
      when 'subscribe' then store_subscribe_path(@customer,promo_code_args)
      when 'index' then store_path(@customer, promo_code_args.merge(:what => params[:what]))
      else store_path(@customer,promo_code_args)
      end
    flash[:alert] = msg
    redirect_to redirect_target
  end

  def purchasemethod_from_params
    # for a regular customer, the only options are 'credit' or 'none' (the latter only valid
    #  if a zero-price order)

    # if Stripe successfully registered a CC purchase, 'fake' the :commit parameter (Submit
    # button value) to look like 'credit card'
    params[:commit] = 'credit' if params[:_stripe_commit] =~ /credit/
    case params[:commit]
    when ( /credit/i || params[:_stripe_commit] =~ /credit/i)
      meth = Purchasemethod.get_type_by_name('web_cc')
      args = { :credit_card_token => params[:credit_card_token] }
    when /check/i
      return redirect_to(checkout_path, :alert => "Only box office can process check payments") unless @is_admin
      meth = Purchasemethod.get_type_by_name('box_chk')
      args = {:check_number => params[:check_number] }
    when /cash/i
      return redirect_to(checkout_path, :alert => "Only box office can process cash payments") unless @is_admin
      meth = Purchasemethod.get_type_by_name('box_cash')
      args = {}
    when /comp/i
      meth = Purchasemethod.get_type_by_name('none')
      args = {}
    else
      meth = nil
      args = {}
      flash[:alert] = "Invalid form of payment."
    end
    return meth,args
  end

  def setup_for_showdate(sd)
    return if sd.nil?
    @what = sd.show.event_type
    @sd = sd
    @sh = @sd.show
    if @is_admin
      @all_showdates = @sh.showdates
      setup_ticket_menus_for_admin
    else
      @all_showdates = @sh.upcoming_showdates
      setup_ticket_menus_for_patron
    end
  end

  def setup_ticket_menus_for_admin
    @valid_vouchers =
      @sd.valid_vouchers.includes(:vouchertype).to_a.
      delete_if(&:comp?).
      delete_if(&:subscriber_voucher?).
      map do |v|
      v.customer = @customer
      v.adjust_for_customer
    end.sort_by(&:display_order)
    @all_shows = Show.
      all_for_seasons(Time.this_season - 1, Time.this_season + 1).
      of_type(@what)  ||  []
    # ensure default show is included in list of shows
    if (@what == 'Regular Show' && !@all_shows.include?(@sh))
      @all_shows << @sh
    end
  end

  def setup_ticket_menus_for_patron
    @valid_vouchers = @sd.valid_vouchers.includes(:vouchertype).map do |v|
      v.customer = @customer
      v.adjust_for_customer @promo_code
    end.find_all(&:visible?).sort_by(&:display_order)
    
    @all_shows = Show.current_and_future.of_type(@what) || []
    if (@what == 'Regular Show' && !@all_shows.include?(@sh))
      @all_shows << @sh
    end
  end

  def add_tickets_to_cart
    tickets = ValidVoucher.from_params(params[:valid_voucher])
    if @is_admin
      tickets.each_pair { |vv, qty| @cart.add_tickets(vv, qty) }
    else
      promo = params[:promo_code].to_s
      tickets.each_pair do |vv, qty|
        vv.customer = @customer
        @cart.add_with_checking(vv,qty,promo)
      end
    end
  end

  def add_donation_to_cart
    if (amount = to_numeric(params[:donation])) > 0
      @cart.add_donation(
        Donation.from_amount_and_account_code_id(amount, params[:account_code_id], params[:donation_comments]))
    end
  end

  def add_retail_items_to_cart
    return unless @is_admin && params[:retail].to_f > 0.0
    @cart.errors.add(:base, "Retail items can't be included in a gift order") and return if
      params[:gift]
    r = RetailItem.from_amount_description_and_account_code_id(
      *(params.values_at(:retail, :retail_comments, :retail_account_code_id)))
    if r.valid?
      @cart.add_retail_item(r)
    else
      @cart.errors.add(:base, "There were problems with your retail purchase: " <<
        r.errors.full_messages.join(', '))
    end
  end

  def add_service_charge_to_cart
    @cart.add_retail_item RetailItem.new_service_charge_for(params[:what])
  end

end
