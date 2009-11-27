class ReportController < ApplicationController

  include Enumerable
  include Utils
  require 'set'

  before_filter :is_staff_filter

  def index
    # all showdates
    @all_showdates = Showdate.find(:all).sort_by { |s| s.thedate }
    # next showdate
    @next_showdate = @all_showdates.detect { |s| s.thedate >= Time.now }
    # all show names
    @all_shows = Show.find(:all)
    # quick subscription stats
    @subscriptions = Voucher.subscription_vouchers(Time.now.year)
    # list of all special reports
    @special_report_names =
      Dir.entries("#{RAILS_ROOT}/app/models/reports/").select { |x| x.gsub!(/\.rb$/,'') }
  end

  verify(:method => :post, :only => %w[noshow_subscriber mark_fulfilled],
         :add_flash => {:notice => 'ERROR: Action can only be called via POST'})

  def do_report
    # this is a dispatcher that just redirects to the correct report
    # based on a dropdown menu.
    case params[:rep]
    when /transaction/i
      sales_detail
    when /revenue/i
      accounting_report
    when /invoice/i
      invoice
    else
      flash[:notice] = "Please select a valid report."
      redirect_to :action => :index and return
    end
  end

  def advance_sales
    case params[:showdate_id]
    when /^(\d+)$/
      @shows = [Show.find_by_id($1)]
    when /future/i
      @shows = Show.find(:all,
                         :conditions => ['closing_date >= ?', Date.today],
                         :order => 'opening_date')
    when /current/i
      @shows = [Show.find(:first,
                          :conditions => ['closing_date >= ?', Date.today],
                          :order => 'opening_date')]
    else
      @shows = Show.find(:all,:order => 'opening_date')
    end
    if (@shows.empty? rescue nil)
      flash[:notice] = "No shows match your criteria"
      redirect_to :action => 'index'
      return
    end
    render :action => :advance_sales
  end

  def showdate_sales
    entity = Object.const_get(params[:klass]).find(params[:id])
    vouchers = entity.vouchers
    by_vtype = vouchers.group_by(&:vouchertype)
    categories = vouchers.group_by(&:class)
    revenue_per_seat = entity.revenue_per_seat
    render :partial => 'showdate_sales',
    :locals => {
      :total_vouchers => vouchers.size,
      :vouchers => by_vtype,
      :categories => categories,
      :revenue_per_seat => revenue_per_seat
    }
  end

  def sales_detail
    from,to = get_dates_from_params(:from,:to)
    sales = Voucher.sold_between(from, to)
    @nsales = sales.size
    @page_title = "#{@nsales} Transactions: #{from.strftime('%a %b %e')} " <<
      (to - from > 1.day ? (" - " << to.strftime('%a %b %e')) : '')
    @daily_sales = sales.group_by do |v|
      u = v.sold_on
      "#{u.change(:min => u.min - u.min.modulo(3))},#{v.customer.last_name},#{v.customer.first_name},#{v.vouchertype_id},#{v.processed_by_id}"
    end
    @nunique = sales.group_by { |v| v.customer.id }.keys.size
    if @daily_sales.empty?
      flash[:notice] = "No transactions during date range given"
      redirect_to :action => 'index'
      return
    end
    render :action => :sales_detail
  end

  def accounting_report
    @from,@to = get_dates_from_params(:from,:to)
    @page_title =
      "Revenue by Category: #{@from.to_formatted_s(:short)} - #{@to.to_formatted_s(:short)}"
    # get all vouchers sold between these dates where:
    #  - NOT walkup sales
    #  - purchasemethod is some credit card transaction
    #  - vouchertype has a price > 0
    # run report for all vouchertypes such that:
    # - account code is not null
    # - price > 0
    sql_query = <<EOQ1
      SELECT v.purchasemethod_id,vt.account_code,s.name,
                SUM(vt.price) AS totalprice,COUNT(*) AS numunits
        FROM vouchers v
          INNER JOIN vouchertypes vt ON v.vouchertype_id=vt.id
          INNER JOIN showdates sd ON sd.id = v.showdate_id
          INNER JOIN shows s ON s.id = sd.show_id
        WHERE
          v.showdate_id != 0
          AND (v.sold_on BETWEEN ? and ?)
          AND v.customer_id NOT IN (0,?)
        GROUP BY v.purchasemethod_id,vt.account_code,s.name
        ORDER BY v.purchasemethod_id
EOQ1
    sql = [sql_query, @from, @to, Customer.walkup_customer.id]
    @show_txns = Voucher.find_by_sql(sql)
    # next, all the Bundle Vouchers - regardless of purchase method
    sql = ["SELECT vt.name,vt.account_code,SUM(vt.price) " <<
           "FROM vouchers v " <<
           "  INNER JOIN vouchertypes vt ON v.vouchertype_id = vt.id " <<
           "WHERE " <<
           " vt.price > 0" <<
           " AND (v.sold_on BETWEEN ? AND ?)" <<
           " AND v.customer_id NOT IN (0,?)" <<
           " AND vt.bundle = 1 " <<
           "GROUP BY vt.account_code,vt.name",
           @from, @to, Customer.walkup_customer.id]
    @subs_txns = sort_and_filter(Voucher.find_by_sql(sql),"vt.price")
    # last, all the Donations
    sql = ["SELECT df.name,d.account_code,SUM(d.amount) " <<
           "FROM donations d,donation_funds df " <<
           "WHERE d.date BETWEEN ? AND ? " <<
           "GROUP BY d.purchasemethod_id",
           @from, @to]
    @donation_txns = sort_and_filter(Voucher.find_by_sql(sql),"d.amount")
    render :action => :accounting_report
  end

  def subscriber_details
    y = (params[:id] || Time.now.year).to_i
    subs = Voucher.subscription_vouchers(y)
    render :partial => 'subscriptions', :object => subs, :locals => {:year => y}
    if params[:download]
      CSV::Writer.generate(output='') do |csv|
        csv << %w[name price quantity]
        q=0 ; t=0
        subs.each { |s| csv << s ; t += s[1]*s[2] ; q += s[2] }
        csv << ['Total',t,q]
        download_to_excel(output, "subs#{y}")
      end
    end
  end

  def show_special_report
    n = params[:report_name]
    unless n.blank?
      # setup any parameters needed to render the report's partial
      report_subclass = n.camelize.constantize
      @report = report_subclass.__send__(:new)
      @args = @report.view_params
      render :partial => "report/special/#{n}"
    end
  end

  def run_special_report
    n = params[:_report]
    @report = n.constantize.__send__(:new)
    @report.generate(params)
    if @report.errors.blank?
      logger.info @report.log unless @report.log.blank?
      @report.create_csv
      download_to_excel(@report.output, @report.filename, false)
    else
      render :text => "Error generating report: #{@report.errors}"
    end
  end

  def unfulfilled_orders
    v = Voucher.find(:all,
                     :include => :customer,
                     :conditions => 'fulfillment_needed = 1',
                     :order => "customers.last_name")
    if v.empty?
      flash[:notice] = 'No unfulfilled orders at this time.'
      redirect_to :action => 'index'
    end
    @total = v.length
    @vouchers = group_and_count(v) do |v1,v2|
      v1.customer_id == v2.customer_id &&
        v1.vouchertype_id == v2.vouchertype_id &&
        v1.gift_purchaser_id ==  v2.gift_purchaser_id
    end
  end

  def unfulfilled_orders_addresses
    sql = <<-EOQ
     SELECT DISTINCT c.first_name,c.last_name,c.street,c.city,c.state,c.zip
     FROM customers c,vouchers v
     WHERE c.id=v.customer_id AND v.fulfillment_needed=1
EOQ
    @customers = Customer.find_by_sql(sql)
    if @customers.empty?
      flash[:notice] = 'No unfulfilled orders at this time.'
      redirect_to :action => 'index'
      return
    end
    export_customers_to_excel(@customers)
  end

  def mark_fulfilled
    i = 0
    flash[:notice] = ''
    params[:voucher].each_pair do |vid,do_update|
      next if do_update.to_i.zero?
      if (v = Voucher.find(:first, :conditions => ['id = ?', vid.to_i]))
        unless v.fulfillment_needed
          flash[:notice] << "Warning: voucher ID #{vid} was already marked fulfilled<br/>"
        end
        v.fulfillment_needed = false
        v.save!
        i += 1
      end
    end
    flash[:notice] << "#{i} orders marked fulfilled"
    redirect_to :action => 'index'
  end

  def invoice
    start = (Time.now - 1.month).at_beginning_of_month
    @from,@to =
      get_dates_from_params(:from,:to, start, start + 1.month - 1.second)
    @bill = Option.values_hash(:monthly_fee, :cc_fee_markup, :per_ticket_fee, :per_ticket_commission,:customer_service_per_hour,:venue)
    @page_title = "Invoice for #{@bill[:venue]} : " <<
      "#{@from.to_formatted_s(:date_only)} - #{@to.to_formatted_s(:date_only)}"
    # following calc doesn't handle per-ticket commissions, only fixed fees
    raise "Can't invoice based on nonzero per-ticket commission" if
      @bill[:per_ticket_commission] > 0
    sql = <<EOQ2
        SELECT DISTINCT COUNT(*) AS count,
                        SUM(vt.price) AS totalprice,
                        vt.account_code,
                        vt.price,
                        vt.name AS vouchertype_name,
                        s.name AS show_name
        FROM (((vouchers v
                JOIN vouchertypes vt on v.vouchertype_id=vt.id)
                JOIN showdates sd on v.showdate_id=sd.id)
                JOIN shows s on sd.show_id=s.id)
        WHERE (v.sold_on BETWEEN ? AND ?) and vt.price > 0
        GROUP BY vt.account_code,s.id
EOQ2
    @vouchers = Voucher.find_by_sql([sql,@from,@to])
    @total = 0.0
    @subtotal = {}
    @vouchers.each do |vgrp|
      @total +=
        (@subtotal[vgrp.attributes.values_at('show_name','account_code').join(',')] =
         vgrp.attributes['count'].to_f * @bill[:per_ticket_fee])
    end
    @nmonths = ((@to-@from)/1.year) * 12
    @monthly_fee =  @nmonths * @bill[:monthly_fee]
    @customer_service_charges = 0.0 # must compute
    @total += @customer_service_charges + @monthly_fee
    render :action => :invoice
  end


  private

  def export_customers_to_excel(custs)
    filenm = custs.first.class.to_s.downcase
    CSV::Writer.generate(output='') do |csv|
      custs.each do |c|
        csv << [c.first_name.name_capitalize,
                c.last_name.name_capitalize,
                c.street,c.city,c.state,c.zip]
      end
      download_to_excel(output,filenm)
    end
  end

  def get_dates_from_params(from_param,to_param,
                            default_from=Time.now,default_to=Time.now)
    from = Time.from_param(params[from_param],default_from)
    to = Time.from_param(params[to_param],default_to)
    from,to = to,from if from > to
    return from.at_beginning_of_day, to.at_end_of_day
  end



  # given a list of AR records returned from the GROUP BY sql queries of the
  # accounting report, squeeze out the ones with a zero total, and sort
  # the collection by (name,account code) where name may be a show name,
  # subscription-vouchertype name, or donation-type name.
  def sort_and_filter(records,price_key)
    records.reject do |v|
      v.attributes["SUM(#{price_key})"].to_f.zero?
    end.sort_by(&Proc.new do |x|
                  "#{x.attributes['name']},#{x.attributes['account_code']}"
                end).map do |e|
      e.attributes.values_at("account_code", "name", "SUM(#{price_key})")
    end
  end
end
