class DonationsController < ApplicationController

  before_filter :is_staff_filter
  before_filter :load_customer, :only => [:new, :create]

  private

  def load_customer
    redirect_with(donations_path, :alert => 'You must select a customer.') and return unless
      @customer = Customer.find(params[:customer_id])
  end

  public
  
  def index
    @things = []
    @params = {}
    return unless params[:commit] # first time visiting page: don't do "null search"

    conds = {}
    if (params[:use_cid] &&
        (cid = params[:cid].to_i) != 0) &&
        (c = Customer.find_by_id(cid))
      @full_name = c.full_name
      @page_title = "Donation history: #{@full_name}"
      flash[:notice] = "Search restricted to customer #{@full_name}"
      conds.merge!("items.customer_id = ?" => cid)
    else
      @page_title = "Donation history"
    end
    mindate,maxdate = Time.range_from_params(params[:donation_date_from],
                                             params[:donation_date_to])
    mindate = mindate.at_beginning_of_day
    maxdate = maxdate.at_end_of_day
    params[:donation_date_from] = mindate
    params[:donation_date_to] = maxdate
    if params[:use_date]
      conds.merge!("orders.sold_on >= ?" => mindate, "orders.sold_on <= ?" => maxdate)
    end
    if params[:use_amount]
      conds.merge!("amount >= ?" => params[:donation_min].to_f)
      if (donation_max = params[:donation_max].to_f) > 0.0
        conds.merge!("amount <= ?" => donation_max)
      end
    end
    if params[:use_ltr_sent]
      conds.merge!("letter_sent IS NULL" => nil)
    end
    if params[:use_fund] && !params[:donation_funds].blank?
      conds.merge!("account_code_id IN (?)" => params[:donation_funds])
    end
    keys = conds.keys
    conds_array = ([keys.join(" AND ")] + keys.map { |k| conds[k] }).compact
    if conds.empty?
      @things = Donation.find(:all)
    else
      @things = Donation.find(:all, :include => 'order', :conditions => conds_array)
    end
    # also show ticket purchases?
    if (params[:show_vouchers] && c)
      vouchers = c.vouchers.find(:all, :conditions => "showdate_id > 0",
                                 :include => :showdate)
      if params[:use_date]
        vouchers = vouchers.select { |v| v.showdate.thedate.between?(mindate, maxdate) }
      end
      @things += vouchers
    end
    @things = @things.sort_by { |x| (x.kind_of?(Donation) ?
                                     x.order.sold_on.to_time : x.showdate.thedate.to_time) }
    @export_label = "Download in Excel Format"
    @params = params
    if params[:commit] == @export_label
      export(@things.select { |thing| thing.kind_of?(Donation) })
    end
  end

  def new
    @donation ||= @customer.donations.new(:amount => 0,:comments => '')
  end

  def create
    @order = Order.new(:purchaser => @customer, :customer => @customer)
    @donation = Donation.from_amount_and_account_code_id(
      params[:amount].to_f, params[:fund].to_i, params[:comments].to_s)
    @order.add_donation(@donation)
    @order.processed_by = current_user()

    sold_on = Date.from_year_month_day(params[:date])
    case params[:payment]
    when 'check'
      @order.purchasemethod = Purchasemethod.find_by_shortdesc('box_chk')
    when 'cash'
      @order.purchasemethod = Purchasemethod.find_by_shortdesc('box_cash')
    when 'credit_card'
      @order.purchasemethod = Purchasemethod.find_by_shortdesc('box_cc')
      @order.purchase_args =  { :credit_card_token => params[:credit_card_token] }
      sold_on = Time.now
    end
    @order.comments = params[:comments].to_s
    unless @order.ready_for_purchase?
      flash[:alert] = @order.errors.full_messages.join(',')
      render :action => 'new'
      return
    end
    begin
      @order.finalize!(sold_on)
      flash[:notice] = "Donation successfully recorded."
      redirect_to customer_path(@customer)
    rescue Exception => e
      raise e
      # rescue ActiveRecord::RecordInvalid => e
      # rescue Order::OrderFinalizeError => e
      # rescue RuntimeError => e
    end
  end

  def update
    if (t = Donation.find_by_id(params[:id])).kind_of?(Donation)
      now = Time.now
      c = current_user.email rescue "(ERROR)"
      t.update_attributes(:letter_sent => now,
                          :processed_by => current_user)
      Txn.add_audit_record(:cust_id => t.customer_id,
                           :logged_in_id => current_user.id,
                           :txn_type => 'don_ack',
                           :comments => "Donation ID #{t.id} marked as acknowledged")
      render :text => "#{now.strftime("%D")} by #{c}"
    else
      render :text => "(ERROR)"
    end
  end

  private

  def export(donations)
    content_type = (request.user_agent =~ /windows/i ? 'application/vnd.ms-excel' : 'text/csv')
    CSV::Writer.generate(output = '') do |csv|
      csv << %w[last first street city state zip email amount date code fund letterSent]
      donations.each do |d|
        csv << [d.customer.last_name.name_capitalize,
                d.customer.first_name.name_capitalize,
                d.customer.street,
                d.customer.city,
                d.customer.state,
                d.customer.zip,
                d.customer.email,
                d.amount,
                d.sold_on.to_formatted_s(:db),
                d.account_code.code,
                d.account_code.name,
                d.letter_sent]
      end
      send_data(output, :type => content_type,
                :filename => filename_from_date('donations', Time.now, 'csv'))
    end
  end

end
