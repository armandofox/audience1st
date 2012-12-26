class StoreController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => %w(show_changed showdate_changed comment_changed redeeming_promo_code set_promo_code clear_promo_code)

  before_filter :is_logged_in, :only => %w[edit_billing_address]
  before_filter :is_admin_filter, :only => %w[direct_transaction]
  
  before_filter(:find_cart_not_empty,
    :only => %w[edit_billing_address set_shipping_address
                 place_order],
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
                 :index, :subscribe, :special, :donate,
                 :show_changed, :showdate_changed,
                 :shipping_address, :set_shipping_address,
                 :comment_changed,
                 :edit_billing_address)
  
  def index
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
    setup_for_initial_visit unless (@promo_code = redeeming_promo_code)
    @subscriber = @customer.subscriber?
    @next_season_subscriber = @customer.next_season_subscriber?
    set_return_to :action => :index
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
      Vouchertype.bundles_available_to(store_customer, @gAdmin.is_boxoffice).using_promo_code(@promo_code)
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

  def donate
    @account_code = AccountCode.find_by_id(params[:fund]) ||
      AccountCode.default_account_code
  end

  def process_cart
    if params[:commit] =~ /redeem/i # customer entered promo code, redisplay prices
      redirect_to(stored_action.merge({:commit => 'redeem', :promo_code => params[:promo_code]}))
      return
    end
    @cart = find_cart
    @cart.purchaser = store_customer
    @cart.comments = params[:comments]
    @cart.processed_by_id = logged_in_id
    process_ticket_request
    redirect_to_index and return if flash[:warning]
    # all well with cart, try to process donation if any
    if params[:donation].to_i > 0
      d = Donation.online_donation(params[:donation].to_i, params[:account_code_id], store_customer.id,logged_in_id)
      @cart.add_donation(d)
    end
    remember_cart_in_session(@cart)
    if params[:gift] && @cart.include_vouchers?
      redirect_to :action => 'shipping_address'
    else
      @cart.customer = @cart.purchaser
      redirect_to_checkout
    end
  end

  def shipping_address
    #  collect gift recipient info
    @cart = find_cart
    set_checkout_in_progress true
    @recipient = @cart.customer || Customer.new
  end

  def set_shipping_address
    @cart = find_cart
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
        flash[:warning] = recipient.errors.full_messages
        render :action => :shipping_address
        return
      end
    end
    @cart.customer = recipient
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
    @cart = find_cart
    # Work around Rails bug 2298 here
    @sales_final_acknowledged = (params[:sales_final].to_i > 0) || current_admin.is_boxoffice
    @checkout_message = Option.value(:precheckout_popup) ||
      "PLEASE DOUBLE CHECK DATES before submitting your order.  If they're not correct, you will be able to Cancel before placing the order."
    # if this is a "walkup web" sale (not logged in), nil out the
    # customer to avoid modifing the Walkup customer.
    redirect_to change_user_path and return unless logged_in?
  end

  def edit_billing_address
    set_return_to :controller => 'store', :action => 'checkout'
    flash[:notice] = "Please update your credit card billing address below. Click 'Save Changes' when done to continue with your order."
    redirect_to :controller => 'customers', :action => 'edit'
  end

  def place_order
    @cart = find_cart
    @is_admin = current_admin.is_boxoffice
    # what payment type?
    @cart.purchasemethod,@cart.purchase_args = purchasemethod_from_params
    unless @cart.ready_for_purchase?
      flash[:warning] = @cart.errors.full_messages.join(', ')
      redirect_to_checkout
      return
    end
    @recipient = @cart.purchaser
    sales_final = verify_sales_final or return
    if ! @cart.gift?
      # record 'who will pickup' field if necessary
      @cart.comments << "(Pickup by: #{ActionController::Base.helpers.sanitize(params[:pickup])})" unless params[:pickup].blank?
    end

    if @cart.purchasemethod.purchase_medium == :credit_card
      @cart.finalize_by_paying_with_credit_card!
    else
      @cart.finalize!
    end

    if ! @cart.errors.empty?
      flash[:checkout_error] = @cart.errors.full_messages.join(', ')
      logger.info("FAILED purchase for #{@cart.customer}: #{@cart.errors.inspect}") rescue nil
      redirect_to_checkout
      return
    end

    logger.info("SUCCESS purchase #{@cart.customer}; Cart summary: #{@cart.summary}")
    if params[:email_confirmation]
      email_confirmation(:confirm_order,
        @cart.customer,@cart.purchaser,@cart.summary,
        @cart.total_price, @cart.payment_description,
        @cart.all_comments)
    end
    reset_shopping
    set_return_to
  end

  private

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
      @all_showdates = ((is_admin || @sh.special?) ? @sh.showdates :
        @sh.future_showdates)
      # @all_showdates = (is_admin ? @sh.showdates :
      #  @sh.future_showdates.select { |s| s.saleable_seats_left > 0 })
      # make sure originally-selected showdate is included among those
      #  to be displayed.
      unless @all_showdates.include?(@sd)
        @sd = @all_showdates.first
      end
      @vouchertypes = (@sd ?
                       ValidVoucher.numseats_for_showdate(@sd,@customer,:ignore_cutoff => is_admin, :promo_code => @promo_code) :
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
      showdates = Showdate.find(ValidVoucher.for_advance_sales.keys).reject { |sd| (!sd.show.special? && sd.thedate < Date.today || !sd.show.special? != !@special_shows_only)}.sort_by(&:thedate)
    end
  end

  def process_ticket_request
    unless (showdate = Showdate.find_by_id(params[:showdate])) ||
        params[:donation].to_i > 0
      flash[:warning] = "Please select a show date and tickets, or enter a donation amount."
      return
    end
    params[:valid_voucher] ||= {}
    admin = @gAdmin.is_boxoffice
    # pre-check whether the total number of tickets exceeds availability
    total = params[:valid_voucher].values.sum
    if showdate && total > showdate.saleable_seats_left  &&  !admin
      flash[:warning] = "You've requested #{total} tickets, but only #{showdate.saleable_seats_left} are available for this performance."
    else
      params[:valid_voucher].each_pair do |valid_voucher_id, qty|
        @cart.add_tickets(valid_voucher_id, qty)
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

  def remember_cart_in_session(cart)
    if cart.save
      session[:cart] = cart.id
    else
      logger.warn "Couldn't save cart in session: #{cart.errors.full_messages.join(', ')}"
    end
  end
  
  def find_cart_not_empty
    cart = find_cart
    # regular custonmers must have a total order > $0.00, but admins can
    # have zero-cost order as long as has zero items
    if ((@gAdmin.is_staff && cart.cart_items.length > 0) ||
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
    url_or_path = params[:redirect_to]
    if url_or_path.empty?
      redirect_to :action => 'index'
    elsif url_or_path =~ /\//
      redirect_to url_or_path
    else
      redirect_to :action => url_or_path
    end
  end

  def purchasemethod_from_params
    if ( !@is_admin || params[:commit] =~ /credit/ ) 
      meth = Purchasemethod.get_type_by_name(@cart.customer.id == logged_in_id ? 'web_cc' : 'box_cc')
      args = {
        :bill_to => @cart.purchaser,
        :credit_card_token => params[:credit_card_token]
      }
    elsif params[:commit] =~ /check/
      meth = Purchasemethod.get_type_by_name('box_chk')
      args = {:check_number => params[:check_number] }
    elsif params[:commit] =~ /cash/
      meth = Purchasemethod.get_type_by_name('box_cash')
      args = {}
    else
      flash[:warning] = "Invalid form of payment."
      redirect_to_checkout
    end
    return meth,args
  end
end
