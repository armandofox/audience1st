class StoreController < ApplicationController
  include ActiveMerchant::Billing
  include Enumerable

  require "money.rb"

  before_filter :is_logged_in, :only => %w[edit_billing_address]
  before_filter :is_admin, :only => %w[direct_transaction]
  
  before_filter(:find_cart_not_empty,
    :only => %w[edit_billing_address shipping_address set_shipping_address
                checkout place_order not_me],
    :add_to_flash => {:checkout_error => "Your order appears to be empty. Please select some tickets."},
    :redirect_to => {:action => 'index'})
    

  verify(:method => :post,
         :only => %w[add_tickets_to_cart add_donation_to_cart
                        add_subscriptions_to_cart place_order],
         :add_to_flash => {:warning => "SYSTEM ERROR: action only callable as POST"},
         :redirect_to => {:action => 'index'})

  # this should be the last declarative spec since it will append another
  # before_filter
  ssl_required(:checkout, :place_order, :direct_transaction,
                 :index, :subscribe,
                 :show_changed, :showdate_changed,
                 :shipping_address, :set_shipping_address,
                 :comment_changed,
                 :not_me, :edit_billing_address,
                 :enter_promo_code, :add_tickets_to_cart, :add_donation_to_cart,
                :remove_from_cart)
  
  def index
    reset_shopping
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
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
        #set_current_showdate(s.sort.detect { |sd| sd.thedate >= Time.now } || s.first)
        set_current_show((s.sort.detect { |sd| sd.thedate >= Time.now } || s.first).show)
      end
    end
    @subscriber = @customer.is_subscriber?
    @next_season_subscriber = @customer.is_next_season_subscriber?
    @promo_code = session[:promo_code] || nil
    setup_ticket_menus
  end

  def subscribe
    reset_shopping
    session[:redirect_to] = :subscribe
    @customer = store_customer
    @subscriber = @customer.is_subscriber?
    @next_season_subscriber = @customer.is_next_season_subscriber?
    @cart = find_cart
    # this uses the temporary hack of adding bundle sales start/end
    #   to bundle voucher record directly...ugh
    @subs_to_offer = Vouchertype.find_products(:type => :subscription, :for_purchase_by => (@subscriber ? :subscribers : :nonsubscribers), :ignore_cutoff => @gAdmin.is_boxoffice)
    if @subs_to_offer.empty?
      flash[:warning] = "There are no subscriptions on sale at this time."
      redirect_to :action => :index
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
    # if this is a post, add items to cart first (since we're coming from
    #  ticket selection page).  If a get, buyer just wants to modify
    #  gift recipient info.
    # add items to cart
    set_checkout_in_progress
    @cart = find_cart
    @redirect_to = params[:redirect_to] == 'subscribe' ? :subscribe : :index
    if request.post?
      @redirect_to == :subscribe ? process_subscription_request : process_ticket_request
      # did anything go wrong?
      redirect_to :action => :index and return unless flash[:warning].blank?
      if params[:donation].to_i > 0
        @cart.add(Donation.online_donation(params[:donation].to_i, store_customer.id,logged_in_id))
      end
    end
    # make sure something actually got added.
    if @cart.is_empty?
      flash[:warning] = "Please select some tickets."
      redirect_to :action => (params[:redirect_to] || :index)
      return
    end
    # all is well. if this is a gift order, fall through to get Recipient info.
    # if NOT a gift, set recipient to same as current customer, and
    # continue to checkout.
    # in case it's a gift, customer should know donation is made in their name.
    @includes_donation = @cart.items.detect { |v| v.kind_of?(Donation) }
    set_checkout_in_progress
    if params[:gift]
      @recipient = session[:recipient_id] ? Customer.find_by_id(session[:recipient_id]) : Customer.new
    else
      redirect_to :action => :checkout
    end
  end

  def set_shipping_address
    @cart = find_cart
    # if we can find a unique match for the customer AND our existing DB record
    #  has enough contact info, great.  OR, if the new record was already created but
    #  the buyer needs to modify it, great.
    #  Otherwise... create a NEW record based
    #  on the gift receipient information provided.
    if session[:recipient_id]
      @recipient = Customer.find_by_id(session[:recipient_id])
      @recipient.update_attributes(params[:customer])
    elsif ((@recipient = Customer.find_unique(params[:customer])) && # exact match
        @recipient.valid_as_gift_recipient?)                    # valid contact info
      # we're good; unique match, and already valid contact info.
    else
      # assume we'll have to create a new customer record.
      @recipient = Customer.new(params[:customer])
    end
    # make sure minimal info for gift receipient was specified.
    unless  @recipient.valid_as_gift_recipient?
      flash[:warning] = @recipient.errors.full_messages.join "<br/>"
      render :action => :shipping_address
      return
    end
    # try to match customer in DB, or create.
    if @recipient.new_record?
      unless @recipient.save
        flash[:warning] = @recipient.errors.full_messages
        render :action => :shipping_address
        return
      end
    end
    session[:recipient_id] = @recipient.id
    redirect_to :action => :checkout
  end

  def show_changed
    if (id = params[:show_id].to_i) > 0 && (s = Show.find_by_id(id))
      set_current_show(s)
      sd = s.future_showdates
      # set_current_showdate(sd.empty? ? nil : sd.first)
      set_current_showdate(nil)
    end
    setup_ticket_menus
    render :partial => 'ticket_menus'
  end

  def showdate_changed
    if (id = params[:showdate_id].to_i) > 0 && (s = Showdate.find_by_id(id))
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

  def enter_promo_code
    code = (params[:promo_code] || '').upcase
    if !code.empty?
      session[:promo_code] = code
    end
    redirect_to :action => 'index'
  end

  def checkout
    @cust = store_customer
    @is_admin = current_admin.is_boxoffice
    if session[:recipient_id]
      @recipient = Customer.find( session[:recipient_id] )
    else
      @recipient = @cust
    end
    @cart = find_cart
    @sales_final_acknowledged = (params[:sales_final].to_i > 0) || current_admin.is_boxoffice
    if @cart.is_empty?
      logger.warn "Cart empty, redirecting from checkout back to store"
      redirect_to(:action => 'index', :id => params[:id])
      return
    end
    @credit_card = ActiveMerchant::Billing::CreditCard.new
    set_return_to :controller => 'store', :action => 'checkout'
    # if this is a "walkup web" sale (not logged in), nil out the
    # customer to avoid modifing the Walkup customer.
    redirect_to :action => 'not_me' and return if nobody_really_logged_in
  end

  def not_me
    @cust = Customer.new
    set_return_to :controller => 'store', :action => 'checkout'
    flash[:warning] = "Please sign in, or if you don't have an account, please enter your credit card billing address."
    redirect_to :controller => 'customers', :action => 'login'
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
    redirect_to(:action => 'index') and return unless
      @recipient = verify_valid_recipient 
    @cart.gift_from(@customer) unless @recipient == @customer
    # OK, we have a customer record to tie the transaction to
    if (params[:commit] =~ /credit/i || !@is_admin)
      verify_valid_credit_card_purchaser or return
      method = :credit_card
      redirect_to(:action => 'checkout') and return unless
        args = collect_credit_card_info
      args.merge({:order_number => @cart.order_number})
      @payment="credit card #{args[:credit_card].display_number}"
    elsif params[:commit] =~ /check/i
      method = :check
      args = {:check_number => params[:check_number]}
      @payment = "check number #{params[:check_number]}"
    elsif params[:commit] =~ /cash/i
      method = :cash
      args = {}
      @payment = "cash"
    end
    howpurchased = (@customer.id == logged_in_id ? 'cust_ph' : 'cust_web')
    resp = Store.purchase!(method, @cart.total_price, args) do
      # add non-donation items to recipient's account
      @recipient.add_items(@cart.nondonations_only, logged_in_id, howpurchased)
      @recipient.save!
      # add donation items to payer's account
      @customer.add_items(@cart.donations_only, logged_in_id, howpurchased)
      @amount = @cart.total_price
      @order_summary = @cart.to_s
      @special_instructions = @cart.comments
    end
    if resp.success?
      @payment << " (transaction ID: #{resp.params[:transaction_id]})" if
        @payment =~ /credit/i
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
    redirect_to :action => 'checkout', :sales_final => sales_final
  end

  def direct_transaction
    unless request.post?
      @credit_card = CreditCard.new
      @customer = Customer.new
      if RAILS_ENV == 'production'
        flash[:warning] = <<EOM1
WARNING: These are real transactions that will be submitted to the payment
gateway.  Credit cards will really be charged.  Error messages from the
gateway will be returned verbatim.
EOM1
      else
        flash[:warning] = <<EOM2
Because this deployment is in sandbox mode, transactions will NOT be processed.
EOM2
      end
      return
    end
    # send request
    args = collect_credit_card_info
    amount = params[:amount].to_f
    args[:order_number] = Time.now.to_i
    resp = Store.purchase!(:credit_card, amount, args) do
      # nothing to do
    end
    flash[:notice] = <<EON
Success: #{resp.success?} <br/>
Message: #{resp.message} <br/>
Txn ID:  #{resp.params[:transaction_id]}
EON
    redirect_to :action => 'direct_transaction'
  end
    
  private

  def setup_ticket_menus
    @customer = store_customer
    @cart = find_cart
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
#       @all_showdates = (is_admin ? @sh.showdates :
#                         @sh.future_showdates.select { |s| s.total_seats_left > 0 })
      # make sure originally-selected showdate is included among those
      #  to be displayed.
      unless @all_showdates.include?(@sd)
        @sd = @all_showdates.first
      end
      @vouchertypes = (@sd ?
                       ValidVoucher.numseats_for_showdate(@sd.id,@customer,:ignore_cutoff => is_admin) :
                       [] )
    elsif @sh = current_show    # show selected, but not showdate
      @all_showdates = (is_admin ? @sh.showdates :
                        @sh.future_showdates)
#       @all_showdates = (is_admin ? @sh.showdates :
#                         @sh.future_showdates.select { |s| s.total_seats_left > 0 })
      @vouchertypes = []
    else                      # not even show is selected
      @all_showdates = []
      @vouchertypes = []
    end
    # filtering:
    # remove any showdates that are sold out (which could cause showdate menu
    #   to become empty)
    # remove any vouchertypes tht customer should not even see the existence
    #  of (unless "customer" is actually an admin)
    @vouchertypes.reject! { |av| av.staff_only } unless is_admin
    @vouchertypes.reject! { |av| av.howmany.zero? }
    # BUG: must filter vouchertypes by promo code!!
    # @vouchertypes.reject!
  end

  # Customer on whose behalf the store displays are based (for special
  # ticket eligibility, etc.)  Current implementation: same as the active
  # customer, if any; otherwise, the walkup customer.
  # INVARIANT: this MUST return a valid Customer record.
  def store_customer
    current_customer || Customer.walkup_customer
  end

  def reset_current_show_and_showdate ;  session[:store] = {} ;  end
  def set_current_show(s) ; (session[:store] ||= {})[:show] = s ; end
  def set_current_showdate(sd) ; (session[:store] ||= {})[:showdate] = sd ; end
  def current_showdate ;  (session[:store] ||= {})[:showdate] ;  end
  def current_show ; (session[:store] ||= {})[:show] ;  end

  # helpers for the AJAX handlers. These should probably be moved
  # to the respective models for shows and showdates, or called as
  # helpers from the views directly.

  def get_all_shows(showdates)
    showdates.map { |s| s.show }.uniq.sort_by { |s| s.opening_date }
  end

  def get_all_showdates(ignore_cutoff = false)
    if ignore_cutoff
      showdates = Showdate.find(:all, :conditions => ['thedate >= ?', Time.now.at_beginning_of_season - 1.year], :order => "thedate ASC")
    else
      showdates = Showdate.find(ValidVoucher.for_advance_sales.keys).sort_by(&:thedate)
    end
  end

  def get_all_subs(cust = Customer.generic_customer)
    return Vouchertype.find(:all, :conditions => ["bundle = 1 AND offer_public > ?", (cust.kind_of?(Customer) && cust.is_subscriber? ? 0 : 1)])
  end

  def process_ticket_request
    unless (showdate = Showdate.find_by_id(params[:showdate])) ||
        params[:donation].to_i > 0
      flash[:warning] = "Please select a show date and tickets, or enter a donation amount."
      return
    end
    msgs = []
    comments = params[:comments]
    (params[:vouchertype] ||= {}).each_pair do |vtype, qty|
      qty = qty.to_i
      unless qty.zero?
        av = ValidVoucher.numseats_for_showdate_by_vouchertype(showdate, store_customer, vtype, :ignore_cutoff => @gAdmin.is_boxoffice)
        if av.howmany.zero?
          msgs << "Sorry, no '#{Vouchertype.find_by_id(vtype.to_i).name}' tickets available for this performance."
        elsif av.howmany < qty
          msgs << "Only #{av.howmany} '#{Vouchertype.find_by_id(vtype.to_i).name}' tickets available for this performance (you requested #{qty})."
        else
          @cart.comments ||= comments
          qty.times  do
            @cart.add(Voucher.anonymous_voucher_for(showdate,vtype,nil,comments))
            comments = nil      # HACK - only add to first voucher
          end
        end
      end
    end
    flash[:warning] = msgs.join("<br/>") unless msgs.empty?
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
    @customer = current_customer
    unless @customer.kind_of?(Customer)
      flash[:warning] = "SYSTEM ERROR: Invalid purchaser (id=#{@customer.id})"
      logger.error "Reached place_order with invalid customer: #{@customer}"
      redirect_to :action => 'checkout'
      return nil
    end
    @customer
  end

  def verify_valid_credit_card_purchaser
    result = @customer.valid_as_purchaser?
    unless result
      flash[:warning] = "Customer address/contact data insufficient for credit card purchase"
      logger.error "Reached place_order with customer who is invalid as purchaser: #{@customer}"
      redirect_to :action => 'checkout'
    end
    result
  end
    

  def collect_credit_card_info
    bill_to = Customer.new(params[:customer])
    cc_info = params[:credit_card].symbolize_keys
    cc_info[:first_name] = bill_to.first_name
    cc_info[:last_name] = bill_to.last_name
    # BUG: workaround bug in xmlbase.rb where to_int (nonexistent) is
    # called rather than to_i to convert month and year to ints.
    cc_info[:month] = cc_info[:month].to_i
    cc_info[:year] = cc_info[:year].to_i
    cc = CreditCard.new(cc_info)
    # prevalidations: CC# and address appear valid, amount >0,
    # billing address appears to be a well-formed address
    if (RAILS_ENV == 'production' && !cc.valid?) # format check on credit card number
      flash[:checkout_error] =
        "<p>Please provide valid credit card information:</p> <ul><li>" <<
        cc.errors.full_messages.join("</li><li>") <<
        "</li></ul>"
      return nil
    end
    return {:credit_card => cc, :bill_to => bill_to}
  end

  def find_cart_not_empty
    cart = find_cart
    # regular customers must have a total order > $0.00, but admins can
    # have zero-cost order as long as has zero items
    if @gAdmin.is_staff
      return (cart.items.length > 0) ? cart : nil
    else
      return (cart.total_price > 0) ? cart : nil
    end
  end

  def verify_sales_final
    if (sales_final = params[:sales_final].to_i).zero?
      flash[:checkout_error] = "Please indicate your acceptance of our Sales Final policy by checking the box."
      redirect_to :action => 'checkout'
      return nil
    else
      return sales_final
    end
  end
end
