class BoxOfficeController < ApplicationController

  before_filter(:is_boxoffice_filter,
                :redirect_to => { :controller => :customers, :action => :login})

  before_filter :get_showdates

  # sets the instance variable @showdate for every method.
  before_filter :get_showdate
  verify(:method => :post,
         :only => :do_walkup_sale,
         :redirect_to => { :action => :walkup },
         :add_to_flash => "Warning: action only callable as POST, no transactions were recorded! ")

  ssl_required(:walkup, :do_walkup_sale)

  private

  # this filter must return non-nil for any method on this controller,
  # or else force a redirect to a different controller & action
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

  # this filter sets up showdates for _showdate_stats panel
  def get_showdates
    @showdates = Showdate.all_shows_this_season
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
      @num_subscribers = perf_vouchers.select { |v| v.customer.is_subscriber? }.size
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
    @showdate = Showdate.find_by_id(params[:id]) || Showdate.current_or_next
    @valid_vouchers = @showdate.valid_vouchers
  end

  def do_walkup_sale
    qtys = params[:qty]
    donation = params[:donation].to_f
    if (qtys.values.map(&:to_i).sum.zero?  &&  donation.zero?)
      flash[:warning] = "No tickets or donation to process"
      redirect_to(:action => 'walkup', :id => @showdate) and return
    end
    begin
      total = compute_price(qtys, donation) 
    rescue Exception => e
      flash[:warning] =
        "There was a problem verifying the amount of the order:<br/>#{e.message}"
      redirect_to(:action => 'walkup', :id => @showdate) and return
    end
    if total == 0.0 # zero-cost purchase
      process_walkup_vouchers(qtys, p=Purchasemethod.find_by_shortdesc('none'))
      Txn.add_audit_record(:txn_type => 'tkt_purch',
                           :customer_id => Customer.walkup_customer.id,
                           :comments => 'walkup',
                           :purchasemethod_id => p,
                           :logged_in_id => logged_in_id)
    else
      case params[:commit]
      when /credit/i
        raise "Credit card swipe processing not yet implemented"
        method,how = :credit_card, Purchasemethod.find_by_shortdesc('box_cc')
      when /cash/i
        method,how = :cash, Purchasemethod.find_by_shortdesc('box_cash')
      when /check/i
        method,how = :check, Purchasemethod.find_by_shortdesc('box_chk')
      end
      resp = Store.purchase!(method,total) do
        process_walkup_vouchers(qtys, how)
        Donation.walkup_donation(donation,logged_in_id) if donation > 0.0
        Txn.add_audit_record(:txn_type => 'tkt_purch',
                             :customer_id => Customer.walkup_customer.id,
                             :comments => 'walkup',
                             :purchasemethod_id => how,
                             :logged_in_id => logged_in_id)
      end
      flash[:notice] = "Transaction NOT processed: #{resp.message}" unless
        resp.success?
    end
    redirect_to :action => 'walkup', :id => @showdate
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
