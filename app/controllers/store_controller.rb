class StoreController < ApplicationController
  include ActiveMerchant::Billing
  include Enumerable

  require "money.rb"

  skip_before_filter :verify_authenticity_token, :only => %w(show_changed showdate_changed comment_changed redeeming_promo_code set_promo_code clear_promo_code)

  before_filter :is_logged_in, :only => %w[edit_billing_address]
  before_filter :is_admin_filter, :only => %w[direct_transaction]
  
  before_filter(:find_cart_not_empty,
    :only => %w[edit_billing_address set_shipping_address
                 place_order not_me],
    :add_to_flash => {:warning => "Your order appears to be empty. Please select some tickets."},
    :redirect_to => {:action => 'index'})
    

  verify(:method => :post,
         :only => %w[add_tickets_to_cart add_donation_to_cart
                        add_subscriptions_to_cart place_order],
         :add_to_flash => {:warning => "SYSTEM ERROR: action only callable as POST"},
         :redirect_to => {:action => 'index'})

  # this should be the last declarative spec since it will append another
  # before_filter
  ssl_required(:checkout, :place_order, :direct_transaction,
                 :index, :subscribe, :special,
                 :show_changed, :showdate_changed,
                 :shipping_address, :set_shipping_address,
                 :comment_changed,
                 :not_me, :edit_billing_address)
  
  def index
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
    setup_for_initial_visit unless (@promo_code = redeeming_promo_code)
    @subscriber = @customer.subscriber?
    @next_season_subscriber = @customer.next_season_subscriber?
    setup_ticket_menus
  end

  def special
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
    @special_shows_only = true
    setup_for_initial_visit unless (@promo_code = redeeming_promo_code)
    @subscriber = @customer.subscriber?
    @next_season_subscriber = @customer.next_season_subscriber?
    setup_ticket_menus
    set_return_to :controller => 'store', :action => 'special'
    render :action => 'index'
  end

  def subscribe
    reset_shopping
    set_return_to :controller => 'store', :action => 'subscribe'
    @customer = store_customer
    @subscriber = @customer.subscriber?
    @next_season_subscriber = @customer.next_season_subscriber?
    @cart = find_cart
    # this uses the temporary hack of adding bundle sales start/end
    #   to bundle voucher record directly...ugh
    @promo_code = redeeming_promo_code
    @subs_to_offer =
      Vouchertype.subscriptions_available_to(store_customer, @gAdmin.is_boxoffice).using_promo_code(@promo_code)
    if @subs_to_offer.empty?
      flash[:warning] = "There are no subscriptions on sale at this time."
      redirect_to_index
      return
    end
    if (v = params[:vouchertype_id]).to_i > 0 && # default selected subscription
        vt = Vouchertype.find_by_id(v) &&
        # note! must use grep (uses ===) rather than include (uses ==)
        @subs_to_offer.grep(vt)
      @selected_sub = v.to_i
    end
  end

  def shipping_address
    redirect_to(stored_action.merge({:commit => 'redeem', :promo_code => params[:promo_code]})) and return if params[:commit] =~ /redeem/i
    # if this is a post, add items to cart first (since we're coming from
    #  ticket selection page).  If a get, buyer just wants to modify
    #  gift recipient info.
    # add items to cart
    @cart = find_cart
    @redirect_to = params[:redirect_to] == 'subscribe' ? :subscribe : :index
    if request.post?
      @redirect_to == :subscribe ? process_subscription_request : process_ticket_request
      # did anything go wrong?
      redirect_to_index and return unless flash[:warning].blank?
      if params[:donation].to_i > 0
        d = Donation.online_donation(params[:donation].to_i, store_customer.id,logged_in_id)
        @cart.add(d)
      end
    end
    # did anything get added to cart?
    if @cart.empty?
      flash[:warning] = "Nothing was added to your order. Please try again."
      redirect_to_index
      return
    end
    # all is well. if this is a gift order, fall through to get Recipient info.
    # if NOT a gift, or if donation only, set recipient to same as current customer, and
    # continue to checkout.
    # in case it's a gift, customer should know donation is made in their name.
    @includes_donation = @cart.include_donation?
    set_checkout_in_progress(true)
    if params[:gift] && @cart.include_vouchers?
      @recipient = session[:recipient_id] ? Customer.find_by_id(session[:recipient_id]) : Customer.new
    else
      redirect_to_checkout
    end
  end

  def set_shipping_address
    @cart = find_cart
    # if we can find a unique match for the customer AND our existing DB record
    #  has enough contact info, great.  OR, if the new record was already created but
    #  the buyer needs to modify it, great.
    #  Otherwise... create a NEW record based
    #  on the gift receipient information provided.
    @recipient = recipient_from_session || recipient_from_params ||
      Customer.new(params[:customer])
    # make sure minimal info for gift receipient was specified.
    @recipient.gift_recipient_only = true
    if @recipient.new_record?
      @recipient.created_by_admin = true if current_admin.is_boxoffice
      unless @recipient.save
        flash[:warning] = @recipient.errors.full_messages
        render :action => :shipping_address
        return
      end
    end
    session[:recipient_id] = @recipient.id
    redirect_to_checkout
  end

  def show_changed
    if (id = params[:show_id].to_i) > 0 && (s = Show.find_by_id(id))
      @special_shows_only = s.special?
      set_current_show(s)
    end
    setup_ticket_menus
    render :partial => 'ticket_menus'
  end

  def showdate_changed
    if (id = params[:showdate_id].to_i) > 0 && (s = Showdate.find_by_id(id))
      @special_shows_only = s.show.special?
      set_current_showdate(s)
    end
    setup_ticket_menus
    render :partial => 'ticket_menus'
  end

  def comment_changed
    cart = find_cart
    cart.comments = params[:comments]
    render :nothing => true
  end

  def checkout
    set_return_to :controller => 'store', :action => 'checkout'
    @cust = store_customer
    @is_admin = current_admin.is_boxoffice
    if session[:recipient_id]
      @recipient = Customer.find( session[:recipient_id] )
    else
      @recipient = @cust
    end
    @cart = find_cart_not_empty or return
    # Work around Rails bug 2298 here
    @cart.workaround_rails_bug_2298!
    logger.info "Checkout:\n#{@cart}"
    @sales_final_acknowledged = (params[:sales_final].to_i > 0) || current_admin.is_boxoffice
    if @cart.empty?
      logger.warn "Cart empty, redirecting from checkout back to store"
      redirect_to_index
      return
    end
    @credit_card = ActiveMerchant::Billing::CreditCard.new
    @double_check_dates = @cart.double_check_dates
    set_return_to :controller => 'store', :action => 'checkout'
    # if this is a "walkup web" sale (not logged in), nil out the
    # customer to avoid modifing the Walkup customer.
    redirect_to :action => 'not_me' and return unless logged_in?
  end

  def not_me
    @cust = Customer.new
    set_return_to :controller => 'store', :action => 'checkout'
    flash[:warning] = "Please sign in, or if you don't have an account, please enter your credit card billing address."
    redirect_to login_path
  end

  def edit_billing_address
    set_return_to :controller => 'store', :action => 'checkout'
    flash[:notice] = "Please update your credit card billing address below. Click 'Save Changes' when done to continue with your order."
    redirect_to :controller => 'customers', :action => 'edit'
  end

  def place_order
    @cart = find_cart_not_empty or return
    @customer = verify_valid_customer or return
    @is_admin = current_admin.is_boxoffice
    sales_final = verify_sales_final or return
    redirect_to_index and return unless
      @recipient = verify_valid_recipient 
    @cart.gift_from(@customer) unless @recipient == @customer
    # OK, we have a customer record to tie the transaction to
    howpurchased = Purchasemethod.default
    # regular customers can only purchase with credit card
    params[:commit] = 'credit' if !@is_admin
    if params[:commit] =~ /check/i
      method = :check
      howpurchased = Purchasemethod.get_type_by_name('box_chk')
      args = {:check_number => params[:check_number]}
      @payment = params[:check_number].blank? ? "by check" : "with check number #{params[:check_number]}"
    elsif params[:commit] =~ /cash/i
      method = :cash
      howpurchased = Purchasemethod.get_type_by_name('box_cash')
      args = {}
      @payment = "in cash"
    else                        # credit card
      verify_valid_credit_card_purchaser or return
      method = :credit_card
      howpurchased = Purchasemethod.get_type_by_name(@customer.id == logged_in_id ? 'web_cc' : 'box_cc')
      args = {
        :bill_to => Customer.new(params[:customer]),
        :credit_card_token => params[:credit_card_token],
        :order_number => @cart.order_number
      }
      @payment="with credit card"
    end
    resp = Store.purchase!(method, @cart.total_price, args) do
      # add non-donation items to recipient's account
      @recipient.add_items(@cart.nondonations_only, logged_in_id, howpurchased)
      unless (@recipient.save)
        s = @recipient.errors.full_messages.join(', ')
        logger.error "Save failed, re-raising exception! #{s}"
        raise s
      end
      # add donation items to payer's account
      unless  @customer.add_items(@cart.donations_only, logged_in_id, howpurchased)
        logger.error "Add items for #{@customer.full_name_with_id} of #{@cart} failed!"
        raise "Add items failed!"
      end
      @amount = @cart.total_price
      @order_summary = @cart.to_s
      @special_instructions = @cart.comments
    end
    if resp.success?
      @payment << " (transaction ID: #{resp.params["transaction_id"]})" if
        @payment =~ /credit/i
      logger.info("SUCCESS purchase #{@customer.id} [#{@customer.full_name}] by #{@payment}; Cart summary: #{@cart}")
      if params[:email_confirmation]
        email_confirmation(:confirm_order, @customer,@recipient,@order_summary,
          @amount, @payment,
          @special_instructions)
      end
      reset_shopping
      set_return_to
      return
    end
    # failure....
    flash[:checkout_error] = resp.message
    logger.info("FAILED purchase for #{@customer.id} [#{@customer.full_name}] by #{@payment}:\n #{resp.message}") rescue nil
    redirect_to_checkout
  end

  private

  def too_many_tickets_for(showdate)
    # if a donation only, skip this check
    return nil unless showdate
    total = params[:vouchertype].values.inject(0) { |t,qty| t+qty.to_i }
    if total > showdate.saleable_seats_left
      flash[:warning] = "You've requested #{total} tickets, but only #{showdate.saleable_seats_left} are available for this performance."
    else
      nil
    end
  end

  def redeeming_promo_code
    clear_promo_code and return nil if params[:commit] =~ /clear/i
    params[:commit] =~ /redeem/i ? set_promo_code(params[:promo_code]) : nil
  end

  def clear_promo_code
    session.delete(:promo_code)
    logger.info("Clearing promo code")
  end

  def set_promo_code(str)
    promo_code = (str || '').upcase
    params.delete(:commit)
    session[:promo_code] = promo_code
    logger.info "Accepted promo code #{promo_code}"
    promo_code
  end

  def setup_ticket_menus
    @customer = store_customer
    @cart = find_cart
    @promo_code = session[:promo_code]
    is_admin = current_admin.is_boxoffice
    # will set the following instance variables:
    # @all_shows - choice for Shows menu
    # @sh - selected show; nil means none selected
    # @all_showdates - choices for Showdates menu
    # @sd - selected showdate; nil means none selected
    # @vouchertypes - array of AvailableSeat objects indicating vouchertypes
    #   to offer, which includes how many are available
    #   empty array means must choose showdate first
    @all_shows = get_all_shows(get_all_showdates(is_admin))
    if @sd = current_showdate   # everything keys off of selected showdate
      @sh = @sd.show
      @all_showdates = (is_admin ? @sh.showdates :
        @sh.future_showdates)
      # @all_showdates = (is_admin ? @sh.showdates :
      #  @sh.future_showdates.select { |s| s.saleable_seats_left > 0 })
      # make sure originally-selected showdate is included among those
      #  to be displayed.
      unless @all_showdates.include?(@sd)
        @sd = @all_showdates.first
      end
      @vouchertypes = (@sd ?
                       ValidVoucher.numseats_for_showdate(@sd.id,@customer,:ignore_cutoff => is_admin, :promo_code => @promo_code) :
        [] )
      @vouchertypes = @vouchertypes.sort do |a,b|
        ord = (a.vouchertype.display_order <=> b.vouchertype.display_order)
        ord == 0 ? a.vouchertype.price <=> b.vouchertype.price : ord
      end
    elsif @sh = current_show    # show selected, but not showdate
      @all_showdates = (is_admin ? @sh.showdates :
        @sh.future_showdates)
      @vouchertypes = []
    else                      # not even show is selected
      @all_showdates = []
      @vouchertypes = []
    end
    # filtering: unless "customer" is an admin,
    #  remove vouchertypes that customer shouldn't see
    @vouchertypes.reject! { |av| av.staff_only } unless is_admin
    # remove vouchertypes that are sold out (which could cause showdate menu
    #   to become empty) 
    @vouchertypes.reject! { |av|  av.howmany.zero? } unless is_admin
  end

  # Customer on whose behalf the store displays are based (for special
  # ticket eligibility, etc.)  Current implementation: same as the active
  # customer, if any; otherwise, the walkup customer.
  # INVARIANT: this MUST return a valid Customer record.
  def store_customer
    current_user || Customer.walkup_customer
  end

  def reset_current_show_and_showdate ;  session[:store] = {} ;  end
  def set_current_show(s)
    session[:store] ||= {}
    if !(sd = (@gAdmin.is_boxoffice ? s.showdates : s.future_showdates)).empty?
      set_current_showdate(sd.first)
    else
      session[:store][:show] = session[:store][:showdate] = nil
    end
  end
  def set_current_showdate(sd)
    session[:store] ||= {}
    if sd && sd.kind_of?(Showdate)
      session[:store][:showdate] = sd.id
      session[:store][:show] = sd.show.id
    else
      session[:store][:show] = session[:store][:showdate] = nil
    end
  end
  def current_showdate
    if session[:store] && session[:store][:showdate]
      s = Showdate.find_by_id(session[:store][:showdate].to_i)
      !s.show.special? == !@special_shows_only ? s : nil
    else
      nil
    end
  end
  def current_show
    if session[:store] && session[:store][:show]
      s = Show.find_by_id(session[:store][:show].to_i)
      !s.special? == !@special_shows_only ? s : nil
    else
      nil
    end
  end

  # helpers for the AJAX handlers. These should probably be moved
  # to the respective models for shows and showdates, or called as
  # helpers from the views directly.

  def get_all_shows(showdates)
    s = showdates.map { |s| s.show }.uniq.sort_by { |s| s.opening_date }
    unless @gAdmin.is_boxoffice
      s.reject! { |sh| sh.listing_date > Date.today }
    end
    # display only regular shows, or only special shows
    s.reject! { |sh| !(sh.special?) != !(@special_shows_only) }
    s
  end

  def get_all_showdates(ignore_cutoff = false)
    if ignore_cutoff
      showdates = Showdate.find(:all,
        :include => :show,
        :conditions => ['showdates.thedate >= ?' ,Time.now.at_beginning_of_season - 1.year],
        :order => "thedate ASC").reject { |sd| !sd.show.special? != !@special_shows_only }
    else
      showdates = Showdate.find(ValidVoucher.for_advance_sales.keys).reject { |sd| (sd.thedate < Date.today || !sd.show.special? != !@special_shows_only)}.sort_by(&:thedate)
    end
  end

  def process_ticket_request
    unless (showdate = Showdate.find_by_id(params[:showdate])) ||
        params[:donation].to_i > 0
      flash[:warning] = "Please select a show date and tickets, or enter a donation amount."
      return
    end
    msgs = []
    comments = params[:comments]
    params[:vouchertype] ||= {}
    admin = @gAdmin.is_boxoffice
    # pre-check whether the total number of tickets exceeds availability
    return if (!admin && too_many_tickets_for(showdate))
    params[:vouchertype].each_pair do |vtype, qty|
      qty = qty.to_i
      unless qty.zero?
        av = ValidVoucher.numseats_for_showdate_by_vouchertype(showdate, store_customer, vtype, :ignore_cutoff => admin, :promo_code => session[:promo_code])
        if (!admin && av.howmany.zero?)
          msgs << "Sorry, no '#{Vouchertype.find_by_id(vtype.to_i).name}' tickets available for this performance."
        elsif (!admin && (av.howmany < qty))
          msgs << "Only #{av.howmany} '#{Vouchertype.find_by_id(vtype.to_i).name}' tickets available for this performance (you requested #{qty})."
        else # either admin, or there's enough seats
          @cart.comments ||= comments
          qty.times  do
            @cart.add(Voucher.anonymous_voucher_for(showdate,vtype,nil,comments))
            comments = nil      # HACK - only add to first voucher
          end
        end
      end
    end
    flash[:warning] = msgs.join("<br/>") unless msgs.empty?
    logger.info "Added to cart: #{@cart}"
  end

  def process_subscription_request
    # subscription tickets
    # BUG should check eligibility here
    params[:vouchertype].each_pair do |vtype, qty|
      unless qty.to_i.zero?
        qty.to_i.times { @cart.add(Voucher.anonymous_bundle_for(vtype)) }
      end
    end
  end

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

  def verify_valid_recipient
    if session[:recipient_id]
      # buyer is different from recipient
      unless recipient = Customer.find_by_id(session[:recipient_id])
        flash[:warning] = 'Gift recipient is invalid'
        logger.error "Gift order, but invalid recipient; id=#{session[:recipient_id]}"
        return nil
      end
    else
      recipient = @customer
    end
    recipient
  end

  def verify_valid_customer
    @customer = current_user
    unless @customer.kind_of?(Customer)
      flash[:warning] = "SYSTEM ERROR: Invalid purchaser (id=#{@customer.id})"
      logger.error "Reached place_order with invalid customer: #{@customer}"
      redirect_to_index
      return nil
    end
    @customer
  end

  def verify_valid_credit_card_purchaser
    result = @customer.valid_as_purchaser?
    unless result
      flash[:warning] = "Customer address/contact data insufficient for credit card purchase"
      logger.error "Reached place_order with customer who is invalid as purchaser: #{@customer}"
      redirect_to_checkout
    end
    result
  end
    
  def find_cart_not_empty
    cart = find_cart
    logger.info "Cart: #{cart.to_s}"
    # regular custonmers must have a total order > $0.00, but admins can
    # have zero-cost order as long as has zero items
    if ((@gAdmin.is_staff && cart.items.length > 0) ||
        cart.total_price > 0)
      return cart
    else
      flash[:warning] = "Your cart is empty - please add tickets and/or a donation."
      redirect_to_index
      return nil
    end
  end

  def verify_sales_final
    return true if Option.value(:terms_of_sale).blank?
    if (sales_final = params[:sales_final].to_i).zero?
      flash[:checkout_error] = "Please indicate your acceptance of our Sales Final policy by checking the box."
      redirect_to_checkout
      return nil
    else
      return sales_final
    end
  end

  def setup_for_initial_visit
    # first visit to store/index
    reset_shopping
    set_return_to :controller => 'store', :action => 'index'
    # if this is initial visit to page, reset ticket choice info
    reset_current_show_and_showdate
    if (id = params[:showdate_id].to_i) > 0 && (s = Showdate.find_by_id(id))
      set_current_showdate(s)
    elsif (!(params[:date].blank?) && (s = Showdate.find_by_date(Time.parse(params[:date]))))
      set_current_showdate(s)
    elsif (id = params[:show_id].to_i) > 0 && (s = Show.find_by_id(id))
      set_current_show(s)
    else                        # neither: pick earliest show
      s = get_all_showdates(@is_admin)
      unless (s.nil? || s.empty?)
        set_current_show((s.sort.detect { |sd| sd.thedate >= Time.now } || s.first).show)
      end
    end
  end
  
  def redirect_to_checkout
    redirect_to(:action => 'checkout',
      :sales_final => params[:sales_final],
      :email_confirmation => params[:email_confirmation])
    true
  end

  def redirect_to_index
    redirect_to :action => (params[:redirect_to] == 'subscribe' ? 'subscribe' : 'index')
    true
  end
end
