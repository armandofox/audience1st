class BoxOfficeController < ApplicationController

  before_filter(:is_boxoffice_filter,
                :redirect_to => { :controller => :customers, :action => :login})

  # sets  instance variable @showdate and others for every method.
  before_filter :get_showdate, :except => :mark_checked_in
  verify(:method => :post,
         :only => %w(do_walkup_sale modify_walkup_vouchers),
         :redirect_to => { :action => :walkup, :id => @showdate },
    :add_to_flash => {:warning => "Warning: action only callable as POST, no transactions were recorded! "})
  verify :method => :post, :only => :mark_checked_in
  ssl_required(:walkup, :do_walkup_sale)
  ssl_allowed :change_showdate
  
  private

  # this filter must setup @showdates and @showdate to non-nil,
  # or else force a redirect to a different controller & action
  def get_showdate
    @showdates = Showdate.find(:all,
      :conditions => ['thedate >= ?', Time.now.at_beginning_of_season - 1.year],
      :order => "thedate ASC")
    return true if (!params[:id].blank?) &&
      (@showdate = Showdate.find_by_id(params[:id].to_i))
    if (@showdate = (Showdate.current_or_next(2.hours) ||
                    Showdate.find(:first, :order => "thedate DESC")))
      redirect_to :action => action_name, :id => @showdate
    else
      flash[:notice] = "There are no shows listed.  Please add some."
      redirect_to :controller => 'shows', :action => 'index'
    end
  end

  def vouchers_for_showdate(showdate)
    perf_vouchers = @showdate.advance_sales_vouchers
    total = perf_vouchers.size
    num_subscribers = perf_vouchers.select { |v| v.customer.subscriber? }.size
    vouchers = perf_vouchers.group_by do |v|
      "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
    end
    return [total,num_subscribers,vouchers]
  end

  def at_least_1_ticket_or_donation
    if (@qty.values.map(&:to_i).sum.zero?  &&  @donation.zero?)
      logger.info(flash[:warning] = "No tickets or donation to process")
      nil
    else
      true
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



  def destroy_vouchers(voucher_ids)
    begin
      Voucher.transaction do 
        voucher_ids.each { |v| Voucher.find(v).destroy }
      end
      flash[:notice] = "Vouchers #{voucher_ids.join(', ')} destroyed."
    rescue Exception => e
      flash[:warning] = "Error (NO changes have been made): #{e.message}"
    end
  end

  def transfer_vouchers(voucher_ids, showdate_id)
    unless sd = Showdate.find_by_id(showdate_id)
      flash[:warning] = "Couldn't transfer vouchers: showdate id #{showdate_id} doesn't exist."
      return
    end
    begin
      Voucher.transaction do
        voucher_ids.each { |v| v.unreserve; v.reserve(sd, logged_in) }
      end
      flash[:notice] = "Vouchers #{voucher_ids.join(', ')} transferred to #{sd.printable_name}."
    rescue Exception => e
      flash[:warning] = "Error (NO changes have been made): #{e.message}"
    end
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
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
  end

  def mark_checked_in
    render :nothing => true and return unless params[:vouchers]
    vouchers = params[:vouchers].split(/,/).map { |v| Voucher.find_by_id(v) }.compact
    if params[:uncheck]
      vouchers.map { |v| v.un_check_in! }
    else
      vouchers.map { |v| v.check_in! }
    end
    render :update do |page|
      showdate = vouchers.first.showdate
      page.replace_html 'show_stats', :partial => 'show_stats', :locals => {:showdate => showdate}
      if params[:uncheck]
        vouchers.each { |v| page[v.id.to_s].removeClassName('checked_in') }
      else
        vouchers.each { |v| page[v.id.to_s].addClassName('checked_in') }
      end
    end
  end

  def door_list
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
    if @vouchers.empty?
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to :action => 'walkup', :id => @showdate
    else
      render :layout => 'door_list'
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
    redirect_to :action => 'walkup', :id => @showdate and return unless at_least_1_ticket_or_donation
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
    @vouchers = @showdate.walkup_vouchers.group_by(&:purchasemethod)
    @other_showdates = @showdate.show.showdates
  end

  # process a change of walkup vouchers by either destroying them or moving them
  # to another showdate, as directed
  def modify_walkup_vouchers
    voucher_ids = params[:vouchers]
    if voucher_ids.blank?
      flash[:warning] = "You didn't select any vouchers to remove or transfer."
    elsif params[:commit] =~ /destroy/i
      destroy_vouchers(voucher_ids)
    else
      transfer_vouchers(voucher_ids, params[:to_showdate])
    end
    redirect_to :action => :index
  end

    

end
