class BoxOfficeController < ApplicationController

  before_filter(:is_boxoffice_filter,
                :redirect_to => { :controller => :customers, :action => :login})

  # sets  instance variable @showdate and others for every method.
  before_filter :get_showdate
  verify(:method => :post,
         :only => :do_walkup_sale,
         :redirect_to => { :action => :walkup, :id => @showdate },
    :add_to_flash => {:warning => "Warning: action only callable as POST, no transactions were recorded! "})

  ssl_required(:walkup, :do_walkup_sale)
  ssl_allowed :change_showdate
  filter_parameter_logging :swipe_data
  filter_parameter_logging :number, :type, :verification_value, :year, :month
  
  private

  # this filter must return non-nil for any method on this controller,
  # or else force a redirect to a different controller & action
  def get_showdate
    @showdates = Showdate.find(:all, :conditions => ['thedate >= ?', Time.now.at_beginning_of_season - 1.year], :order => "thedate ASC")
    return true if (!params[:id].blank?) &&
      (@showdate = Showdate.find_by_id(params[:id].to_i))
    if (showdate = (Showdate.current_or_next ||
                    Showdate.find(:first, :order => "thedate DESC")))
      redirect_to :action => action_name, :id => showdate
    else
      flash[:notice] = "There are no shows listed.  Please add some."
      redirect_to :controller => 'shows', :action => 'index'
    end
  end

  # given a hash of valid-voucher ID's and quantities, compute the total
  # price represented if those vouchers were to be purchase

  def compute_price(qtys,donation='')
    total = 0.0
    qtys.each_pair do |vtype,q|
      total += q.to_i * ValidVoucher.find(vtype).price
    end
    total += donation.to_f
    total
  end

  # process a sale of walkup vouchers by linking them to the walkup customer
  # pass a hash of {ValidVoucher ID => quantity} pairs
  
  def process_walkup_vouchers(qtys,howpurchased = Purchasemethod.find_by_shortdesc('none'))
    vouchers = []
    qtys.each_pair do |vtype,q|
      vv = ValidVoucher.find(vtype)
      vouchers += vv.instantiate(logged_in_id, howpurchased, q.to_i)
    end
    Customer.walkup_customer.vouchers += vouchers
    (flash[:notice] ||= "") << "Successfully added #{vouchers.size} vouchers"
  end

  # collect credit card info: if there is a swipe_data field, parse it and
  # return a CreditCard object; otherwise collect data from actual form fields

  def collect_brief_credit_card_info
    args = {}
    if (s = params[:swipe_data]).blank?
      cc = CreditCard.new(params[:credit_card])
    else
      cc = Store.process_swipe_data(s)
      cc.verification_value = params[:credit_card][:verification_value]
    end
    # allow testing using bogus credit card types
    return("Invalid credit card information: " <<
      cc.errors.full_messages.join(', ') <<
      (s.blank? ? '' : '(try entering manually)')) unless cc.valid?
    args[:credit_card] = cc
    # generate bill_to argument
    args[:bill_to] = Customer.new(:first_name => cc.first_name, :last_name => cc.last_name)
    # generate order number
    args[:order_num] = Cart.generate_order_id
    args
  end

  public

  def index
    redirect_to :action => :walkup
  end

  def change_showdate
    unless ((sd = params[:id].to_i) &&
            (showdate = Showdate.find_by_id(sd)))
      flash[:notice] = "Invalid show date."
    end
    redirect_to :action => 'walkup', :id => sd
  end

  def checkin
    flash[:warning] = "Interactive checkin not yet implemented (coming soon)"
    redirect_to :action => 'walkup', :id => @showdate
  end

  def door_list
    perf_vouchers = @showdate.vouchers
    unless perf_vouchers.empty?
      @total = perf_vouchers.size
      @num_subscribers = perf_vouchers.select { |v| v.customer.subscriber? }.size
      @vouchers = perf_vouchers.group_by do |v|
        "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
      end
      render :layout => 'door_list'
    else
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to :action => 'walkup', :id => @showdate
    end
  end

  def walkup
    @showdate = (Showdate.find_by_id(params[:id]) ||
      Showdate.current_or_next(2.hours))
    @valid_vouchers = @showdate.valid_vouchers
    @credit_card = CreditCard.new # needed by credit-card swipe functions
    @qty = params[:qty] || {}     # voucher quantities
  end

  def do_walkup_sale
    @qty = params[:qty]
    @donation = params[:donation].to_f
    if (@qty.values.map(&:to_i).sum.zero?  &&  @donation.zero?)
      logger.info(flash[:warning] = "No tickets or donation to process")
      redirect_to(:action => 'walkup', :id => @showdate) and return
    end
    begin
      total = compute_price(@qty, @donation) 
    rescue Exception => e
      flash[:warning] =
        "There was a problem verifying the amount of the order:<br/>#{e.message}"
      redirect_to(:action => 'walkup', :id => @showdate) and return
    end
    if total == 0.0 # zero-cost purchase
      process_walkup_vouchers(@qty, p=Purchasemethod.find_by_shortdesc('none'))
      Txn.add_audit_record(:txn_type => 'tkt_purch',
                           :customer_id => Customer.walkup_customer.id,
                           :comments => 'walkup',
                           :purchasemethod_id => p,
                           :logged_in_id => logged_in_id)
      flash[:notice] << " as zero-revenue order"
      logger.info "Zero revenue order successful"
      redirect_to :action => 'walkup', :id => @showdate
      return
    end
    # if there was a swipe_data field, a credit card was swiped, so
    # assume it was a credit card purchase; otherwise depends on which
    # submit button was used.
    params[:commit] = 'credit' unless
      params[:swipe_data].blank? &&
      [:first_name,:last_name,:number,:verification_value].each { |f| params[:credit_card][f].blank? }
    case params[:commit]
    when /credit/i
      method,how = :credit_card, Purchasemethod.find_by_shortdesc('box_cc')
      unless (args = collect_brief_credit_card_info).kind_of?(Hash)
        flash[:notice] = args
        logger.info "Credit card validation failed: #{args}"
        redirect_to(:action => 'walkup', :id => @showdate, :qty => @qty, :donation => @donation)
        return
      end
    when /cash|zero/i
      method,how = :cash, Purchasemethod.find_by_shortdesc('box_cash')
      args = {}
    when /check/i
      method,how = :check, Purchasemethod.find_by_shortdesc('box_chk')
      args = {}
    else
      logger.info(flash[:notice] = "Unrecognized purchase type: #{params[:commit]}")
      redirect_to(:action => 'walkup', :id => @showdate, :qty => @qty, :donation => @donation) and return
    end
    resp = Store.purchase!(method,total,args) do
      process_walkup_vouchers(@qty, how)
      Donation.walkup_donation(@donation,logged_in_id) if @donation > 0.0
      Txn.add_audit_record(:txn_type => 'tkt_purch',
        :customer_id => Customer.walkup_customer.id,
        :comments => 'walkup',
        :purchasemethod_id => how.id,
        :logged_in_id => logged_in_id)
    end
    if resp.success?
      flash[:notice] << " purchased via #{how.description}"
      logger.info "Successful #{how.description} walkup"
      redirect_to :action => 'walkup', :id => @showdate
    else
      flash[:warning] = "Transaction NOT processed: #{resp.message}"
      flash[:notice] = ''
      logger.info "Failed walkup sale: #{resp.message}"
      redirect_to :action => 'walkup', :id => @showdate, :qty => @qty, :donation => @donation
    end
  end

  def walkup_report
    unless (@showdate = Showdate.find_by_id(params[:id]))
      flash[:notice] = "Walkup sales report requires valid showdate ID"
      redirect_to :action => 'index'
      return
    end
    @cash_tix_types = Hash.new(0)
    @cc_tix_types = Hash.new(0)
    @chk_tix_types = Hash.new(0)
    @showdate.vouchertypes.each do |v|
      @cash_tix_types[v] += @showdate.vouchers.count(:conditions => ['vouchertype_id = ? AND purchasemethod_id = ?', v.id, Purchasemethod.get_type_by_name('box_cash')])
      @cc_tix_types[v] += @showdate.vouchers.count(:conditions => ['vouchertype_id = ? AND purchasemethod_id = ?', v.id, Purchasemethod.get_type_by_name('box_cc')])
      @chk_tix_types[v] += @showdate.vouchers.count(:conditions => ['vouchertype_id = ? AND purchasemethod_id = ?', v.id, Purchasemethod.get_type_by_name('box_chk')])
    end
  end

end
