class ReportsController < ApplicationController

  include Enumerable
  include Utils
  require 'set'

  before_filter :is_staff_filter

  def index
    # all showdates
    @all_showdates = Showdate.find(:all).sort_by { |s| s.thedate }
    # next showdate
    @next_showdate = Showdate.next_or_latest
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
    @from,@to = Time.range_from_params(params[:from],params[:to])
    case params[:rep]
    when /transaction/i
      sales_detail
    when /unearned/i
      flash[:warning] = "Improved donations/unearned revenue report coming soon.  In the meantime please click Donation tab and use the Donation Search function."
      redirect_to :action => 'index' and return
    when /earned/i
      accounting_report
    else
      flash[:notice] = "Please select a valid report."
      redirect_to(:action => 'index') and return
    end
  end

  def advance_sales
    if (params[:shows].blank? ||
        (@shows = params[:shows].map { |s| Show.find_by_id(s) }.flatten).empty?)
      flash[:warning] = "Please select one or more shows."
      redirect_to :action => :index
    end
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
      :revenue_per_seat => revenue_per_seat,
      :entity => entity
    }
  end

  def sales_detail
    sales = Voucher.sold_between(@from, @to)
    @nsales = sales.size
    @page_title = "#{@nsales} Transactions: #{@from.strftime('%a %b %e')} " <<
      (@to - @from > 1.day ? (" - " << @to.strftime('%a %b %e')) : '')
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
    if params[:format] =~ /csv/i
      content_type = (request.user_agent =~ /windows/i ? 'application/vnd.ms-excel' : 'text/csv')
      send_data(AccountingReport.render_csv(:from => @from, :to => @to),
        :type => content_type,
        :filename => filename_from_dates('revenue', @from, @to, 'csv'))
    elsif params[:format] =~ /pdf/i
      send_data(AccountingReport.render_pdf(:from => @from, :to => @to),
        :type => 'application/pdf',
        :filename => filename_from_dates('revenue', @from, @to, 'pdf'))
    else
      @report = AccountingReport.render_html(:from => @from, :to => @to)
      render :action => 'accounting_report'
    end
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
    unless (n.blank? || n =~ /select report/i)
      # setup any parameters needed to render the report's partial
      report_subclass = n.camelize.constantize
      @report = report_subclass.__send__(:new)
      @args = @report.view_params
      @sublists = EmailList.get_sublists unless EmailList.disabled?
      render :partial => "reports/special_report", :locals => {:name => n}
    end
  end

  def create_sublist
    name = params[:sublist_name]
    @error_messages = EmailList.errors unless EmailList.create_sublist(name)
    @sublists = EmailList.get_sublists
    render :partial => 'sublist'
  end

  def run_special_report
    n = params[:_report]
    logger.debug request.request_uri
    @report = n.camelize.constantize.__send__(:new, params[:output])
    if (n.blank? || @report.nil? || !@report.kind_of?(Report))
      flash[:warning] = "Error: unknown report name."
      redirect_to(:action => 'index')
      return
    end
    result = @report.generate_and_postprocess(params) # error!
    unless result
      respond_to do |wants|
        wants.html {
          flash[:warning] = "Errors generating report: #{@report.errors}"
          redirect_to :action => 'index'
        }
        wants.js {
          render :text => "Error: #{@report.errors}"
        }
      end
      return
    end
    # success
    respond_to do |wants|
      wants.html {
        case params[:commit]
        when /download/i
          @report.create_csv
          download_to_excel(@report.output, @report.filename, false)
        when /add/i
          l = @report.customers.length
          seg = params[:sublist]
          result = EmailList.add_to_sublist(seg, @report.customers)
          flash[:notice] = "#{result} customers added to sublist '#{seg}'. " <<
            EmailList.errors.to_s
          redirect_to :action => :index
        end
      }
      wants.js {
        if result
          # just render the number of results that would be returned
          render :text => "#{@report.customers.length} matches"
        else # error
        end
      }
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
    @vouchers = v
    @unique_addresses = v.group_by { |vc| vc.customer.street }.keys.length
  end

  def unfulfilled_orders_addresses
    sql = <<-EOQ
     SELECT DISTINCT c.*
     FROM customers c,vouchers v
     WHERE c.id=v.customer_id AND v.fulfillment_needed=1
EOQ
    @customers = Customer.find_by_sql(sql)
    if @customers.empty?
      flash[:notice] = 'No unfulfilled orders at this time.'
      redirect_to :action => 'index'
      return
    end
    output = Customer.to_csv(@customers)
    download_to_excel(output, 'customers')
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
        v.fulfillment_needed = nil
        v.save!
        i += 1
      end
    end
    flash[:notice] << "#{i} orders marked fulfilled"
    redirect_to :action => 'index'
  end

  private

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
