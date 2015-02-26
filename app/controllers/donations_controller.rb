class DonationsController < ApplicationController

  before_filter :is_staff_filter

  def index
    unless params[:commit]
      # first time visiting page: don't do "null search"
      @things = []
      @params = {}
      render :action => 'index' and return
    end
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
    @customer = Customer.find params[:id]
    @donation ||= @customer.donations.new(:amount => 0)
  end

  def create
    @customer = Customer.find params[:id]
    @order = Order.new_from_donation(params[:amount], AccountCode.find(params[:fund]), @customer)
    sold_on = Date.from_year_month_day(params[:date])
    @order.purchasemethod = (params[:payment] == 'check' ?
      Purchasemethod.find_by_shortdesc('box_chk') :
      Purchasemethod.find_by_shortdesc('box_cash'))
    @order.processed_by = @gAdmin
    @order.comments = params[:comments].to_s
    unless @order.ready_for_purchase?
      flash[:alert] = @order.errors.full_messages.join(',')
      render :action => 'new'
      return
    end
    begin
      @order.finalize!(sold_on)
    rescue Exception => e
      raise e
      # rescue ActiveRecord::RecordInvalid => e
      # rescue Order::OrderFinalizeError => e
      # rescue RuntimeError => e
    end
    flash[:notice] = "Donation successfully recorded."
    redirect_to welcome_path
  end

  def mark_ltr_sent
    id = params[:id]
    if (t = Donation.find_by_id(params[:id])).kind_of?(Donation)
      now = Time.now
      c = Customer.find(logged_in_id).email rescue "(ERROR)"
      t.update_attributes(:letter_sent => now,
                          :processed_by_id => logged_in_id)
      Txn.add_audit_record(:cust_id => t.customer_id,
                           :logged_in_id => logged_in_id,
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
