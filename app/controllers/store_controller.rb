class StoreController < ApplicationController
  include ActiveMerchant::Billing
  include Enumerable

  require "money.rb"

  before_filter :walkup_sales_filter, :only => %w[walkup do_walkup_sale]
  before_filter :is_logged_in, :only => %w[edit_billing_address]

  if RAILS_ENV == 'production'
    ssl_required :checkout, :place_order, :walkup, :do_walkup_sale
    ssl_allowed(:index,
                :show_changed, :showdate_changed, :enter_promo_code,
                :add_tickets_to_cart, :add_donation_to_cart, :remove_from_cart,
                :empty_cart, :process_swipe)
  end

  verify(:method => :post,
         :only => %w[do_walkup_sale add_tickets_to_cart add_donation_to_cart
                        add_subscriptions_to_cart place_order],
         :add_flash => {:warning => "SYSTEM ERROR: action only callable as POST"},
         :redirect_to => {:action => 'index'})

  def index
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
    session[:checkout_in_progress] = true
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
        set_current_showdate(s.sort.detect { |sd| sd.thedate >= Time.now } || s.first)
      end
    end
    @subscriber = @customer.is_subscriber?
    @promo_code = session[:promo_code] || nil
    @cart = find_cart
    setup_ticket_menus
  end

  def setup_ticket_menus
    @customer = store_customer
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
                        @sh.future_showdates.select { |s| s.total_seats_left > 0 })
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
                        @sh.future_showdates.select { |s| s.total_seats_left > 0 })
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

  def show_changed
    if (id = params[:show_id].to_i) > 0 && (s = Show.find_by_id(id))
      set_current_show(s)
      sd = s.future_showdates
      set_current_showdate(sd.empty? ? nil : sd.first)
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

  def enter_promo_code
    code = (params[:promo_code] || '').upcase
    if !code.empty?
      session[:promo_code] = code
    end
    redirect_to :action => 'index'
  end

  def subscribe
    @customer = store_customer
    @subscriber = @customer.is_subscriber?
    @cart = find_cart
    # this uses the temporary hack of adding bundle sales start/end
    #   to bundle voucher record directly...ugh
    @subs_to_offer = Vouchertype.find(:all, :conditions => "is_bundle = 1 AND is_subscription = 1 AND (NOW() BETWEEN bundle_sales_start AND bundle_sales_end)").sort_by(&:price).reverse
    if (v = params[:vouchertype_id]).to_i > 0 && # default selected subscription
        vt = Vouchertype.find_by_id(v) &&
        # note! must use grep (uses ===) rather than include (uses ==)
        @subs_to_offer.grep(vt)
      @selected_sub = v.to_i
    end
  end

  def add_subscriptions_to_cart
    @cart = find_cart
    qty = params[:subscription_qty].to_i
    vtype = params[:subscription_vouchertype_id].to_i
    if qty < 1
      flash[:warning] = "Quantity must be 1 or more."
    else
      unless (((v = Vouchertype.find(vtype)).is_subscription? && v.is_bundle?) rescue nil)
        flash[:warning] = "Invalid subscription type."
      else
        1.upto(qty) do
          @cart.add(Voucher.anonymous_bundle_for(vtype))
        end
      end
    end
    redirect_to :action => 'subscribe', :id => params[:id]
  end

  def add_tickets_to_cart
    @customer = store_customer
    @is_admin = current_admin.is_boxoffice
    qtys = params[:vouchertype] # a hash of vouchertypeID => qty of this type
    showdate_id = params[:showdate].to_i
    flash[:warning] = ""

    qtys.reject! { |v,q| q.to_i.zero? }
    flash[:warning] = "Please select one or more tickets." and redirect_to(:action => :index) and return if qtys.empty?
    qtys.each_pair do |vtype_str,qty_str|
      vtype,qty = vtype_str.to_i, qty_str.to_i
      unless (vt = Vouchertype.find_by_id(vtype))
        flash[:warning] << "Ticket ID #{vtype} is invalid. "
        next
      end
      if qty > 99
        flash[:warning] << "Please specify between 1 and 99 tickets for type '#{vt.name}'. "
        next
      end
      av = ValidVoucher.numseats_for_showdate_by_vouchertype(showdate_id,@customer,vtype,:ignore_cutoff => @is_admin)
      flash[:warning] <<
        "Ticket type '#{vt.name}' not valid for that show, or show sold out. " and next if av.howmany.zero?
      flash[:warning] <<
        "Only #{av.howmany} '#{vt.name}' tickets remaining for selected performance. "  and next if av.howmany < qty
      # add vouchers to cart.  Vouchers will be validated at checkout.
      # was a promo code necessary to select this vouchertype?
      promo_code = ((session[:promo_code] && av.promo_codes) ?
                    session[:promo_code].upcase : nil)
      cart = find_cart
      1.upto(qty) do
        cart.add(Voucher.anonymous_voucher_for(showdate_id, vtype, promo_code, params[:comments]))
      end
    end
    #reset_current_show_and_showdate
    params[:showdate] = showdate_id # refresh screen back to same showdate
    redirect_to :action => 'index'
  end

  def add_donation_to_cart
    cart = find_cart
    if (d = params[:donation_amount].to_i) > 0
      cart.add(Donation.online_donation(d, store_customer.id, logged_in_id))
    else
      flash[:warning] = "Please enter a donation amount."
    end
    redirect_to :action =>(params[:redirect_to] || 'index')
  end

  def checkout
    @cust = store_customer
    @cart = find_cart
    @sales_final_acknowledged = (params[:sales_final].to_i > 0) || current_admin.is_boxoffice
    if @cart.is_empty?
      flash[:warning] = "There is nothing in your cart."
      redirect_to :action => 'index', :id => params[:id]
      return
    end
    set_return_to :controller => 'store', :action => 'checkout'
    # if this is a "walkup web" sale (not logged in), nil out the
    # customer to avoid modifing the Walkup customer.
    redirect_to :action => 'not_me' and return if nobody_really_logged_in
    # else reset flag indicating 'login needed', fall thru to checkout screen
    # NOTE: @gCheckoutInProgress is actually set in a global before_filter,
    # but we override it in this *one* place since the normal checkout
    # screen already includes a render of the cart.
    @gCheckoutInProgress = session[:checkout_in_progress] = false
  end

  def not_me
    @cust = Customer.new
    session[:checkout_in_progress] = true
    flash[:warning] = "Please sign in, or create an account if you don't already have one, to enter your credit card billing address.  We never share this information with anyone."
    redirect_to :controller => 'customers', :action => 'login'
  end

  def edit_billing_address
    session[:checkout_in_progress] = true
    flash[:notice] = "Please update your credit card billing address below. Click 'Save Changes' when done to continue with your order."
    redirect_to :controller => 'customers', :action => 'edit'
  end

  def place_order
    @cart = find_cart
    sales_final = params[:sales_final]
    @bill_to = params[:customer]
    cc_info = params[:credit_card].symbolize_keys
    cc_info[:first_name] = @bill_to[:first_name]
    cc_info[:last_name] = @bill_to[:last_name]
    # BUG: workaround bug in xmlbase.rb where to_int (nonexistent) is
    # called rather than to_i to convert month and year to ints.
    cc_info[:month] = cc_info[:month].to_i
    cc_info[:year] = cc_info[:year].to_i
    cc = CreditCard.new(cc_info)
    # prevalidations: CC# and address appear valid, amount >0,
    # billing address appears to be a well-formed address
    unless (errors = do_prevalidations(params, @cart, @bill_to, cc)).empty?
      flash[:checkout_error] = errors
      redirect_to :action => 'checkout', :sales_final => sales_final
      return
    end
    #
    # basic prevalidations OK, continue with customer validation
    #
    @customer = current_customer
    @is_admin = current_admin.is_boxoffice
    unless @customer.kind_of?(Customer)
      flash[:notice] = @customer
      redirect_to :action => 'checkout', :sales_final => sales_final
      return
    end
    # OK, we have a customer record to tie the transaction to
    resp = do_cc_not_present_transaction(@cart.total_price, cc, @bill_to)
    if !resp.success?
      flash[:checkout_error] = "Payment gateway error: " << resp.message
      flash[:checkout_error] << "<br/>Please contact your credit card
        issuer for assistance."  if resp.message.match(/decline/i)
      logger.info("DECLINED: Cust id #{@customer.id} [#{@customer.full_name}] card xxxx..#{cc.number[-4..-1]}: #{resp.message}") rescue nil
      redirect_to :action => 'checkout', :sales_final => sales_final
      return
    end
    #     All is well, fall through to confirmation
    #
    @tid = resp.params['transaction_id'] || '0'
    @customer.add_items(@cart.items, logged_in_id,
                        (current_admin.is_boxoffice ? 'cust_ph' : 'cust_web'),
                        @tid)
    @customer.save
    @amount = @cart.total_price
    @order_summary = @cart.to_s
    @cc_number = (cc.number || 'XXXX').to_s
    email_confirmation(:confirm_order, @customer,@order_summary,
                       @amount, "Credit card ending in #{@cc_number[-4..-1]}")
    @cart.empty!
    session[:promo_code] =  nil
    session[:checkout_in_progress] = nil
    set_return_to
  end

  def remove_from_cart
    @cart = find_cart
    @cart.remove_index(params[:item])
    redirect_to :action => (params[:redirect_to] || 'index')
  end

  def empty_cart
    session[:cart] = Cart.new
    session[:promo_code] = nil
    set_checkout_in_progress(false)
    redirect_to :action => (params[:redirect_to] || 'index')
  end

  def walkup
    # walkup sales are restricted to either boxoffice staff or
    # specific IP's
    @ip = request.remote_ip
    # generate one-time pad for encrypting CC#s
    session[:otp] = @otp = String.random_string(256)
    now = Time.now
    @showdates = Showdate.find(:all,:conditions => ["thedate >= ?", now-1.week])
    # bail out right now if there are no showdate for which to sell
    if @showdates.empty?
      flash[:notice] = "No upcoming shows for walkup sales"
      redirect_to :controller => 'shows', :action => 'list'
      return
    end
    @shows = get_all_shows(@showdates).map  { |s| [s,@showdates.select { |sd| sd.show_id == s.id } ]}
    @vouchertypes = Vouchertype.find(:all, :conditions => ["is_bundle = ? AND walkup_sale_allowed = ?", false, true])
    # if there was a show and showdate selected before redirect to this screen,
    # keep it selected
    if (params[:show])
      @show_id = params[:show].to_i
      @showdate_id = params[:showdate] ? params[:showdate].to_i : nil
    elsif (future_shows = @showdates.select { |x| x.thedate >= (now - 2.hours) })
      next_show = future_shows.min
      @showdate_id = next_show.id
      @show_id = next_show.show.id
    else
      @show_id = @showdate_id = nil # defaults
    end
  end

  def do_walkup_sale
    if params[:commit].match(/report/i) # generate report
      redirect_to(:controller => 'report', :action => 'walkup_sales',
                  :showdate_id => params[:showdate_select])
      return
    end
    qtys = params[:qty]
    showdate = params[:showdate_select]
    # CAUTION: disable_with on a Submit button makes its name (params[:commit])
    # empty on submit!
    is_cc_purch = !(params[:commit] && params[:commit] != APP_CONFIG[:cc_purch])
    vouchers = []
    # recompute the price
    total = 0.0
    ntix = 0
    begin
      qtys.each_pair do |vtype,q|
        ntix += (nq = q.to_i)
        total += nq * Vouchertype.find(vtype).price
        nq.times  { vouchers << Voucher.anonymous_voucher_for(showdate, vtype) }
      end
      total += (donation=params[:donation].to_f)
    rescue Exception => e
      flash[:checkout_error] = "There was a problem verifying the total amount of the order:<br/>#{e.message}"
      redirect_to(:action => :walkup, :showdate => showdate,
                  :show => params[:show_select])
      return
    end
    # link record as a walkup customer
    customer = Customer.walkup_customer
    if is_cc_purch
      if false
        cc = CreditCard.new(params[:credit_card])
        # BUG: workaround bug in xmlbase.rb where to_int (nonexistent) is
        # called rather than to_i to convert month and year to ints.
        cc.month = cc.month.to_i
        cc.year = cc.year.to_i
        # run cc transaction....
        resp = do_cc_present_transaction(total,cc)
        unless resp.success?
          flash[:checkout_error] = "PAYMENT GATEWAY ERROR: " + resp.message
          redirect_to :action => 'walkup', :showdate => showdate,
          :show => params[:show_select]
          return
        end
        tid = resp.params['transaction_id']
        flash[:notice] = "Transaction approved (#{tid})<br/>"
      end
      tid = 0
      howpurchased = Purchasemethod.get_type_by_name('box_cc')
      flash[:notice] = "Credit card purchase recorded, "
    else
      tid = 0
      howpurchased = Purchasemethod.get_type_by_name('box_cash')
      flash[:notice] = "Cash purchase recorded, "
    end
    #
    # add tickets to "walkup customer"'s account
    # TBD CONSOLIDATE this with 'place_order' code for normal orders
    #
    unless (vouchers.empty?)
      vouchers.each do |v|
        if v.kind_of?(Voucher)
          v.purchasemethod_id = howpurchased
        end
      end
      customer.add_items(vouchers, logged_in_id, howpurchased, tid)
      customer.save!              # actually, probably unnecessary
      flash[:notice] << sprintf("%d tickets sold,", ntix)
      Txn.add_audit_record(:txn_type => 'tkt_purch',
                           :customer_id => customer.id,
                           :comments => 'walkup',
                           :purchasemethod_id => howpurchased,
                           :logged_in_id => logged_in_id)
    end
    if donation > 0.0
      begin
        Donation.walkup_donation(donation,logged_in_id)
        flash[:notice] << sprintf(" $%.02f donation processed,", donation)
      rescue Exception => e
        flash[:checkout_error] << "Donation could NOT be recorded: #{e.message}"
      end
    end
    flash[:notice] << sprintf(" total $%.02f",  total)
    flash[:notice] << sprintf("<br/>%d seats remaining for this performance",
                              Showdate.find(showdate).total_seats_left)
    redirect_to(:action => 'walkup', :showdate => showdate,
                :show => params[:show_select])
  end

  # AJAX handler called when credit card is swiped thru USB reader
  def process_swipe
    swipe_data = String.new(params[:swipe_data])
    key = session[:otp].to_s
    no_encrypt = (swipe_data[0] == 37)
    if swipe_data && !(swipe_data.empty?)
      swipe_data = encrypt_with(swipe_data, key) unless no_encrypt
      @credit_card = convert_swipe_to_cc_info(swipe_data.chomp)
      @credit_card.number = encrypt_with(@credit_card.number, key) unless no_encrypt
      render :partial => 'credit_card', :locals => {'name_needed'=>true}
    end
  end

  private

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

  def encrypt_with(orig,pad)
    str = String.new(orig)
    for i in (0..str.length-1) do
      str[i] ^= pad[i]
    end
    str
  end

  def convert_swipe_to_cc_info(s)
    # trk1: '%B' accnum '^' last '/' first '^' YYMM svccode(3 chr)
    #   discretionary data (up to 8 chr)  '?'
    # '%B' is a format code for the standard credit card "open" format; format
    # code '%A' would indicate a proprietary encoding
    trk1 = Regexp.new('^%B(\d{1,19})\\^([^/]+)/?([^/]+)?\\^(\d\d)(\d\d)[^?]+\\?', :ignore_case => true)
    # trk2: ';' accnum '=' YY MM svccode(3 chr) discretionary(up to 8 chr) '?'
    trk2 = Regexp.new(';(\d{1,19})=(\d\d)(\d\d).{3,12}\?', :ignore_case => true)

    # if card has a track 1, we use that (even if trk 2 also present)
    # else if only has a track 2, try to use that, but doesn't include name
    # else error.

    if s.match(trk1)
      accnum = Regexp.last_match(1).to_s
      lastname = Regexp.last_match(2).to_s.upcase
      firstname = Regexp.last_match(3).to_s.upcase # may be nil if this field was absent
      expyear = 2000 + Regexp.last_match(4).to_i
      expmonth = Regexp.last_match(5).to_i
    elsif s.match(trk2)
      accnum = Regexp.last_match(1).to_s
      expyear = 2000 + Regexp.last_match(2).to_i
      expmonth = Regexp.last_match(3).to_i
      lastname = firstname = ''
    else
      accnum = lastname = firstname = 'ERROR'
      expyear = expmonth = 0
    end
    CreditCard.new(:first_name => firstname.strip,
                   :last_name => lastname.strip,
                   :month => expmonth.to_i,
                   :year => expyear.to_i,
                   :number => accnum.strip,
                   :type => CreditCard.type?(accnum.strip) || '')
  end

  def populate_cc_object(params)
    cc_info = params[:credit_card].symbolize_keys || {}
    cc_info[:first_name] = @bill_to[:first_name]
    cc_info[:last_name] = @bill_to[:last_name]
    # BUG: workaround bug in xmlbase.rb where to_int (nonexistent) is
    # called rather than to_i to convert month and year to ints.
    cc_info[:month] = cc_info[:month].to_i
    cc_info[:year] = cc_info[:year].to_i
    CreditCard.new(cc_info)
  end

  def do_prevalidations(params,cart,billing_info,cc)
    err = []
    if cart.total_price <= 0
      err << "Total amount of sale must be greater than zero."
    end
    if params[:sales_final].to_i.zero?
      err << "Please indicate your acceptance of our Sales Final policy by checking the box."
    end
    if ! cc.valid?              # format check on credit card number
      err << ("<p>Please provide valid credit card information:</p>" <<
              "<ul><li>" <<
              cc.errors.full_messages.join("</li><li>") <<
              "</li></ul>")
    end
    if !prevalidate_billing_addr(billing_info)
      err = 'Please provide a valid billing name and address.'
    end
    return err.join("<br/>")
  end

  # TBD this should try to prevalidate that the address looks reasonable
  def prevalidate_billing_addr(billinfo) ;   true ;  end

  # the next two functions actually call the payment gateway
  def do_cc_present_transaction(amount, cc)
    params = {
      :order_id => Option.value(:venue_id).to_i,
      :address => {
        :name => "#{cc.first_name} #{cc.last_name}"
      }
    }
    return cc_transaction(amount,cc,params,card_present=true)
  end

  def do_cc_not_present_transaction(amount, cc, bill_to)
    email = bill_to[:login].to_s.default_to("invalid@audience1st.com")
    phone = bill_to[:day_phone].to_s.default_to("555-555-5555")
    params = {
      :order_id => Option.value(:venue_id).to_i,
      :email => email,
      :address =>  {
        :name => "#{bill_to[:first_name]} #{bill_to[:last_name]}",
        :address1 => bill_to[:street],
        :city => bill_to[:city],
        :state => bill_to[:state],
        :zip => bill_to[:zip],
        :phone => phone,
        :country => 'US'
      }
    }
    return cc_transaction(amount,cc,params,card_present=false)
  end

  def cc_transaction(amount,cc,params,card_present)
    amount = Money.us_dollar((100 * amount).to_i)
    if RAILS_ENV == 'production'
      #Base.gateway_mode = :test unless RAILS_ENV == 'production'
      gw = AuthorizedNetGateway.new(:login => Option.value(:pgw_id),
                                    :password => Option.value(:pgw_txn_key))
    else
      Base.gateway_mode = :test
      cc.number = (cc.number.match( /^42/ ) ? '1' : '3')
      gw = BogusGateway.new(:login => Option.value(:pgw_id),
                            :password => Option.value(:pgw_txn_key))
    end
    return gw.purchase(amount, cc, params)
  end

  # helpers for the AJAX handlers. These should probably be moved
  # to the respective models for shows and showdates, or called as
  # helpers from the views directly.

  def get_all_shows(showdates)
    return showdates.map { |s| s.show }.uniq.sort_by { |s| s.opening_date }
  end

  def get_all_showdates(ignore_cutoff=false)
    showdates = Showdate.find(:all)
    unless ignore_cutoff
      now = Time.now
      showdates.reject! { |sd| sd.end_advance_sales < now || sd.thedate < now }
    end
    showdates.sort_by { |s| s.thedate }
  end

  def get_all_subs(cust = Customer.generic_customer)
    return Vouchertype.find(:all, :conditions => ["is_bundle = 1 AND offer_public > ?", (cust.kind_of?(Customer) && cust.is_subscriber? ? 0 : 1)])
  end

  # filter for walkup sales: requires specific privilege OR allows
  # anyone from selected IP addresses

  def walkup_sales_filter
    unless (current_admin.is_walkup ||
            APP_CONFIG[:walkup_locations].include?(request.remote_ip))
      flash[:warning] = 'To process walkup sales, you must either sign in with
        Walkup Sales privilege OR from an approved walkup sales computer.'
      session[:return_to] = request.request_uri
      redirect_to :controller => 'customers', :action => 'login'
    end
  end



end
