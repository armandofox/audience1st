class StoreController < ApplicationController

  include StoreHelper
  
  skip_before_filter :verify_authenticity_token, :only => %w(show_changed showdate_changed)

  before_filter :set_customer, :except => %w[process_donation]
  before_filter :is_logged_in, :only => %w[checkout place_order]
  before_filter :order_is_not_empty, :only => %w[shipping_address checkout place_order]
  
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

  # if order is nil or empty after checkout phase, abort. This should never happen normally,
  # but can happen if customer does weird things trying to have multiple sessions open.
  def order_is_not_empty
    redirect_to store_path, :alert => t('store.errors.empty_order') if
      @gOrderInProgress.nil? || @gOrderInProgress.cart_empty?
  end

  # invariant: after set_customer runs, the URL contains ID of customer doing the shopping
  def set_customer
    logged_in_user = current_user()
    specified_customer = Customer.find_by_id(params[:customer_id])
    # OK to proceed given this URL?
    redirect_customer = resolve_customer_in_url(logged_in_user, specified_customer)
    if redirect_customer == specified_customer # ok to proceed as is
      @customer = specified_customer
    else      
      redirect_to url_for(params.merge(:customer_id => redirect_customer.id, :only_path => true))
    end
  end

  def resolve_customer_in_url(logged_in_user, desired)
    if !logged_in_user
      Customer.anonymous_customer
    elsif  logged_in_user.is_boxoffice
      # someone is logged in. if staff, correct redirect is to the specified user, UNLESS
      # that is a special customer, in which case redirect is to staff member themselves.
      (desired.nil? || desired.special_customer?) ?  logged_in_user : desired
    else                        # regular user is logged in: redir to self
      logged_in_user
    end
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

    @store = Store::Flow.new(current_user(), @customer, @gAdminDisplay, params)
    return redirect_to(store_subscribe_path(@customer)) if params[:what] == 'Subscription'

    @page_title = "#{Option.venue} - Tickets"
    reset_shopping unless (@promo_code = params[:promo_code])

    @show_url = url_for(params.except(:showdate_id).merge(:show_id => 'XXXX', :only_path => true)) # will be used by javascript to construct URLs
    @showdate_url = url_for(params.except(:show_id).merge(:showdate_id => 'XXXX', :only_path => true)) # will be used by javascript to construct URLs
    @reload_url = url_for(params.merge(:promo_code => 'XXXX', :only_path => true))
    @store.setup
  end

  # All following actions can assume @customer is set. Doesn't mean that person is logged in,
  # but valid for eligibility for tickets
  def subscribe
    return_after_login params.except(:customer_id)
    @store = Store::Flow.new(current_user(), @customer, @gAdminDisplay, params)
    @page_title = "#{Option.venue} - Subscriptions"
    @reload_url = url_for(params.merge(:promo_code => 'XXXX'))
    @store.what = 'Subscription'
    reset_shopping unless @promo_code = params[:promo_code]
    # which subscriptions/bundles are available now?
    if @gAdminDisplay
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

  # Serve quick_donate page; POST calls #process_donation
  def donate
    reset_shopping                 # even if order in progress, going to donation page cancels it
    if @customer == Customer.anonymous_customer
      # handle donation as a 'guest checkout', even though may end up being tied to real customer
      @head = "Login for a faster checkout!"
      @customer = Customer.new
      session[:guest_checkout] = true 
      return_after_login params.except(:customer_id)
    end
  end

  def process_donation
    @amount = to_numeric(params[:donation])
    if params[:customer_id].blank?
      customer_params = params.require(:customer).permit(Customer.user_modifiable_attributes)
      @customer = Customer.for_donation(customer_params)
      @customer.errors.empty? or return redirect_to(quick_donate_path(:customer => params[:customer], :donation => @amount), :alert => "Incomplete or invalid donor information: #{@customer.errors.as_html}")
    else     # we got here via a logged-in customer
      @customer = Customer.find params[:customer_id]
    end
    # At this point, the customer has been persisted, so future redirects just use the customer id.
    redirect_route = quick_donate_path(:customer_id => @customer.id, :donation => @amount)
    @amount > 0 or return redirect_to(redirect_route, :alert => 'Donation amount must be provided')
    # Given valid donation, customer, and charge token, create & place credit card order.
    @gOrderInProgress = Order.new_from_donation(@amount, Donation.default_code, @customer)
    @gOrderInProgress.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
    @gOrderInProgress.purchase_args = {:credit_card_token => params[:credit_card_token]}
    @gOrderInProgress.processed_by = @customer
    @gOrderInProgress.comments = params[:comments].to_s
    @gOrderInProgress.ready_for_purchase? or return redirect_to(redirect_route, :alert => @gOrderInProgress.errors.as_html)
    if finalize_order(@gOrderInProgress, send_email_confirmation: @gOrderInProgress.purchaser.valid_email_address?)
      # forget customer after successful guest checkout
      @guest_checkout = true
      logout_keeping_session!
      render :action => 'place_order'
    else
      redirect_to redirect_route, :alert => @gOrderInProgress.errors.as_html
    end
  end

  def process_cart
    @gOrderInProgress = Order.create(:processed_by => current_user)
    @gOrderInProgress.add_comment params[:comments].to_s
    @gOrderInProgress.add_tickets_from_params params[:valid_voucher], current_user, :promo_code => params[:promo_code], :seats => view_context.seats_from_params(params)
    add_retail_items_to_cart
    add_donation_to_cart
    if ! @gOrderInProgress.errors.empty?
      flash[:alert] = @gOrderInProgress.errors.as_html
      @gOrderInProgress.destroy
      return redirect_to(referer_target)
    end
    if @gOrderInProgress.cart_empty?
      flash[:alert] = I18n.t('store.errors.empty_order')
      @gOrderInProgress.destroy
      return redirect_to(referer_target)
    end
    @gOrderInProgress.add_service_charge
    # order looks OK; all subsequent actions should display in-progress order at top of page
    @gOrderInProgress.save!
    set_order_in_progress @gOrderInProgress
    # if gift, first collect separate shipping address...
    if params[:gift] && @gOrderInProgress.includes_vouchers?
      redirect_to shipping_address_path(@customer)
    else
      # otherwise go directly to checkout
      return_after_login params.except(:customer_id).merge(:action => 'checkout')
      redirect_to_checkout
    end
  end

  def shipping_address
    @mailable = @gOrderInProgress.includes_mailable_items?
    @recipient = Customer.new and return if request.get?
    # request is a POST: collect shipping address
    # record whether we should mail to purchaser or recipient
    @gOrderInProgress.ship_to_purchaser = params[:ship_to_purchaser] if params[:mailable_gift_order]
    # if we can find a unique match for the customer AND our existing DB record
    #  has enough contact info, great.  OR, if the new record was already created but
    #  the buyer needs to modify it, great.
    #  Otherwise... create a NEW record based
    #  on the gift receipient information provided.
    customer_params = params.require(:customer).permit(Customer.user_modifiable_attributes)
    try_customer = Customer.new(customer_params).freeze
    recipient = recipient_from_params(customer_params)
    @recipient =  recipient[0]
    if @recipient.email == @customer.email
      flash.now[:alert] = I18n.t('store.errors.gift_diff_email_notice') 
      render :action => :shipping_address
      return
    end 
    if Customer.email_matches_diff_last_name?(try_customer)
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
    @recipient.created_by_admin = @gAdminDisplay if @recipient.new_record?
    @recipient.save!
    @gOrderInProgress.customer = @recipient
    @gOrderInProgress.save!

    if Customer.email_last_name_match_diff_address?(try_customer)
      flash[:notice] = I18n.t('store.gift_matching_email_last_name_diff_address')
    elsif recipient_from_params(customer_params)[1] == "found_matching_customer"
      flash[:notice] = I18n.t('store.gift_recipient_on_file')  
    end
    redirect_to_checkout
  end

  # Beyond this point, purchaser is logged in (or admin is logged in and acting on behalf of purchaser)

  def checkout
    # only show timer if cart has any vouchers for specific dates
    @page_title = "Review Order For #{@customer.full_name}"
    @sales_final_acknowledged = @gAdminDisplay || (params[:sales_final].to_i > 0)
    @checkout_message = (@gOrderInProgress.includes_reserved_vouchers? ? Option.precheckout_popup : '')
    @gOrderInProgress.processed_by ||= current_user()
    @gOrderInProgress.purchaser ||= @customer
    @gOrderInProgress.customer ||= @gOrderInProgress.purchaser
    @gOrderInProgress.save!
  end

  def place_order
    @page_title = "Confirmation of Order #{@gOrderInProgress.id}"
    # what payment type?
    @gOrderInProgress.purchasemethod,@gOrderInProgress.purchase_args = purchasemethod_from_params
    @recipient = @gOrderInProgress.customer
    if ! @gOrderInProgress.gift?
      # record 'who will pickup' field if necessary
      @gOrderInProgress.add_comment(" - Pickup by: #{ActionController::Base.helpers.sanitize(params[:pickup])}") unless params[:pickup].blank?
    end
    if params.has_key?(:customer)
      customer_params = params.require(:customer).permit(Customer.user_modifiable_attributes)
      @gOrderInProgress.purchaser.update_attributes(customer_params)
    end
    unless @gOrderInProgress.ready_for_purchase?
      flash[:alert] = @gOrderInProgress.errors.as_html
      redirect_to_checkout
      return
    end
    if finalize_order(@gOrderInProgress, send_email_confirmation: params[:email_confirmation])
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

  def finalize_order(order, send_email_confirmation: nil)
    success = false
    begin
      order.finalize!
      Rails.logger.error("SUCCESS purchase #{order.customer}; Cart summary: #{order.summary}")
      email_confirmation(:confirm_order,order.purchaser,order) if send_email_confirmation
      success = true
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError => e
      flash[:alert] = order.errors.full_messages
      Rails.logger.error("FAILED purchase for #{order.customer}: #{order.errors.inspect}") rescue nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error: #{e.message} #{e.backtrace}")
      return redirect_to(store_path, :alert => "Sorry, an unexpected problem occurred with your order.  Please try your order again.  Message: #{e.message}")
    end
    success
  end

  def recipient_from_params(customer_params)
    try_customer = Customer.new(customer_params)
    recipient = Customer.find_unique(try_customer)
    (recipient && recipient.valid_as_gift_recipient?) ? [recipient,"found_matching_customer"] : [try_customer, "new_customer"]
  end

  def redirect_to_checkout
    checkout_params = {}
    checkout_params[:sales_final] = true if params[:sales_final]
    checkout_params[:email_confirmation] = true if params[:email_confirmation]
    redirect_to checkout_path(@customer, checkout_params)
    true
  end

  def referer_target
    promo_code_args = (@promo.blank? ? {} : {:promo_code => @promo})
    redirect_target =
      case params[:referer].to_s
      when 'donate' then quick_donate_path # no @customer assumed
      when 'donate_to_fund' then donate_to_fund_path(params[:account_code_id], @customer)
      when 'subscribe' then store_subscribe_path(@customer,promo_code_args)
      when 'index' then store_path(@customer, promo_code_args.merge(:what => params[:what], :showdate_id => params[:showdate_id]))
      else store_path(@customer,promo_code_args)
      end
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
      return redirect_to(checkout_path, :alert => "Only box office can process check payments") unless @gAdminDisplay
      meth = Purchasemethod.get_type_by_name('box_chk')
      args = {:check_number => params[:check_number] }
    when /cash/i
      return redirect_to(checkout_path, :alert => "Only box office can process cash payments") unless @gAdminDisplay
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

  def add_donation_to_cart
    if (amount = to_numeric(params[:donation])) > 0
      @gOrderInProgress.add_donation(
        Donation.from_amount_and_account_code_id(amount, params[:account_code_id], params[:donation_comments]))
    end
  end

  def add_retail_items_to_cart
    return unless @gAdminDisplay && params[:retail].to_f > 0.0
    @gOrderInProgress.errors.add(:base, "Retail items can't be included in a gift order") and return if
      params[:gift]
    r = RetailItem.from_amount_description_and_account_code_id(
      *(params.values_at(:retail, :retail_comments, :retail_account_code_id)))
    if r.valid?
      @gOrderInProgress.add_retail_item(r)
    else
      @gOrderInProgress.errors.add(:base, "There were problems with your retail purchase: " <<
        r.errors.full_messages.join(', '))
    end
  end

end
