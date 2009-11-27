class BoxOfficeController < ApplicationController

  before_filter(:is_boxoffice_filter,
                :redirect_to => { :controller => :customers, :action => :login})

  # sets the instance variable @showdate for every method.
  before_filter :get_showdate
  verify(:method => :post,
         :only => :do_walkup_sale,
         :redirect_to => { :action => :walkup },
         :add_to_flash => "Warning: action only callable as POST, no transactions were recorded! ")

  ssl_required(:walkup, :do_walkup_sale)   if RAILS_ENV == 'production'

  private

  # this filter must return non-nil for any method on this controller
  def get_showdate
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

  public

  def index
    redirect_to :action => :walkup
  end

  def change_showdate
    unless ((sd = params[:id].to_i) &&
            (showdate = Showdate.find_by_id(sd)))
      flash[:notice] = "Invalid show date."
    end
    redirect_to :action => :walkup, :id => sd
  end

  def door_list
    perf_vouchers = @showdate.vouchers
    unless perf_vouchers.empty?
      @total = perf_vouchers.size
      @num_subscribers = perf_vouchers.select { |v| v.customer.is_subscriber? }.size
      @vouchers = perf_vouchers.group_by do |v|
        "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
      end
      render :layout => false
    else
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to :action => 'walkup', :id => @showdate
    end
  end

  def walkup
    @showdates = Showdate.all_shows_this_season
    @showdate = Showdate.find_by_id(params[:id]) || Showdate.current_or_next
    @valid_vouchers = @showdate.valid_vouchers
  end

  def do_walkup_sale
    qtys = params[:qty]
    donation = params[:donation].to_f
    begin
      total = compute_price(qtys, donation) 
    rescue Exception => e
      flash[:warning] =
        "There was a problem verifying the amount of the order:<br/>#{e.message}"
    end
    if total == 0.0 # zero-cost purchase
      process_walkup_vouchers(qtys, Purchasemethod.find_by_shortdesc('none'))
    else
      case params[:commit]
      when /credit/i
        method,how = :credit_card, Purchasemethod.find_by_shortdesc('box_cc')
      when /cash/i
        method,how = :cash, Purchasemethod.find_by_shortdesc('box_cash')
      when /check/i
        method,how = :check, Purchasemethod.find_by_shortdesc('box_chk')
      end
      Store.purchase!(total, :method => method) do
        process_walkup_vouchers(qtys, how)
        Donation.walkup_donation(donation,logged_in_id) if donation > 0.0
      end
    end
    redirect_to :action => 'walkup', :id => @showdate
  end

  def process_walkup_vouchers(qtys,howpurchased = Purchasemethod.find_by_shortdesc('none'))
    c = Customer.walkup_customer
    qtys.each_pair do |vtype,q|
      vv = ValidVoucher.find(vtype)
      c.vouchers += vv.instantiate(logged_in, howpurchased, q.to_i)
    end
    c.save!
    Txn.add_audit_record(:txn_type => 'tkt_purch',
                         :customer_id => customer.id,
                         :comments => 'walkup',
                         :purchasemethod_id => howpurchased,
                         :logged_in_id => logged_in_id)
  end

  def walkup_report
    unless (@showdate = Showdate.find_by_id(params[:id]))
      flash[:notice] = "Walkup sales report requires valid showdate ID"
      redirect_to :action => 'index'
      return
    end
    @cash_tix = @showdate.vouchers.find(:all, :conditions => ['purchasemethod_id = ?', Purchasemethod.get_type_by_name('box_cash')])
    @cash_tix_types = {}
    @cash_tix.each do |v|
      @cash_tix_types[v.vouchertype] = 1 + (@cash_tix_types[v.vouchertype] || 0)
    end
    @cc_tix = @showdate.vouchers.find(:all, :conditions => ['purchasemethod_id = ?', Purchasemethod.get_type_by_name('box_cc')])
    @cc_tix_types = {}
    @cc_tix.each do |v|
      @cc_tix_types[v.vouchertype] = 1 + (@cc_tix_types[v.vouchertype] || 0)
    end
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

end
