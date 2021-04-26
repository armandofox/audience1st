class ReportsController < ApplicationController

  require 'csv'

  before_filter :is_staff_filter

  def index
    # all showdates
    @all_showdates = Showdate.all.order(:thedate)
    # next showdate
    @next_showdate = Showdate.current_or_next
    # all show names
    @all_shows = Show.all.order('listing_date DESC')
    # currently playing show
    @current_show = @next_showdate.try(:show) || @all_shows.first
    # quick subscription stats
    @subscriptions = Voucher.subscription_vouchers(Time.this_season)
    # list of all special reports
    @special_report_names = Report.subclasses.map { |s| ActiveModel::Name.new(s).human }.unshift('Select report...')
  end

  def advance_sales
    show_ids = params[:shows]
    redirect_to(reports_path, :alert => "Please select one or more shows.") if show_ids.blank?
    @shows = Show.where(:id => show_ids).includes(:showdates => :vouchers)
    return unless params[:commit] =~ /download/i # fall through to render on screen
    report = ShowAdvanceSalesReport.new(@shows).generate
    if report.errors.empty?
      download_to_excel(report.csv, "sales_by_show")
    else
      redirect_to(reports_path, :alert => report.errors.as_html)
    end
  end

  def showdate_sales
    entity = Object.const_get(params[:klass])
    render :status => :unprocessable_entity and return unless (entity == Show || entity == Showdate)
    entity = entity.find(params[:id])
    vouchers = entity.vouchers.finalized

    sales = Showdate::Sales.new(vouchers.group_by(&:vouchertype),
      entity.revenue_per_seat, entity.total_offered_for_sale)
    render :partial => 'showdate_sales', :locals => { :sales => sales }
  end

  def subscriber_details
    y = (params[:id] || Time.current.year).to_i
    subs = Voucher.subscription_vouchers(y)
    if params[:download]
      output = CSV.generate do |csv|
        csv << %w[name amount quantity]
        q=0 ; t=0
        subs.each { |s| csv << s ; t += s[1]*s[2] ; q += s[2] }
        csv << ['Total',t,q]
      end
      download_to_excel(output, "subs#{y}")
    else
      render :partial => 'subscriptions', :object => subs, :locals => {:year => y}
    end
  end

  def  attendance
    report_name = params[:special_report_name].to_s.gsub(/\s+/, '_').downcase
    return unless report_subclass = validate_report_type(report_name)
    @report = report_subclass.__send__(:new)
    @args = @report.view_params
    @sublists = EmailList.new.get_sublists
    render :partial => "reports/special_report", :locals => {:name => report_name}
  end

  # This handler is always called as XHR GET, but for one case ("display
  # matches on screen"), it must do a full HTTP redirect.
  skip_before_filter :verify_authenticity_token, :only => :run_special, :if => lambda { request.xhr? }
  def run_special
    return unless (klass = validate_report_type params[:report_name])
    action = params[:what]
    full_report_url = request.fullpath
    @report = klass.__send__(:new, params[:output])
    @report.generate_and_postprocess(params)
    @customers = @report.customers

    if @report.errors
      return render(:js => %Q{alert('#{ActionController::Base.helpers.j @report.errors}')})
    end
    
    if request.xhr? && action =~ /display|download/i
      # if we need a true redirect (for Download or Display On Screen),
      # serialize the form and use JS to force the redirect.  This means we end up
      # running the report twice, but whatever.
      return render(:js => %Q{window.location.href = '#{full_report_url}';}) 
    end

    case action
    when /display/i
      # paginate in case it's a long report
      @customers = @customers.paginate(:page => (params[:page] || 1).to_i)
      @page_title = "Report results: #{params[:report_name].humanize}"
      @list_action = full_report_url
      render :template => 'customers/index'
    when /estimate/i
      render :js => "alert('#{@customers.length} matches')"
    when /download/i
      @report.create_csv
      stream_download_to_excel(@report.output, @report.filename)
    when /add/i
      seg = params[:sublist]
      email_list = EmailList.new
      result = email_list.add_to_sublist(seg, @customers)
      msg = "#{result} customers added to list '#{seg}'. #{email_list.errors}"
      render :js => %Q{alert(#{msg})}
    when /create/i
      name = params[:sublist_name]
      if (num=email_list.create_sublist_with_customers(name, @customers))
        msg = ActionController::Base.helpers.escape_javascript %Q{List "#{name}" created with #{num} customers. #{email_list.errors}}
      else
        msg = ActionController::Base.helpers.escape_javascript %Q{Error creating list "#{name}": #{email_list.errors}}
      end
      render :js => %Q{alert('#{msg}')}
    else
      raise "Unmatched action #{action}"
    end
  end

  def unfulfilled_orders
    @report = UnfulfilledOrdersReport.new
    return redirect_to(reports_path, :notice => 'No unfulfilled orders at this time.') if @report.empty
    if params[:csv]
      send_data @report.as_csv, :type => 'text/csv', :filename => "unfulfilled_#{Date.today}.csv"
    end
  end

  def mark_fulfilled
    i = 0
    flash[:notice] = ''
    params[:voucher].each_pair do |vid,do_update|
      next if do_update.to_i.zero?
      if (v = Voucher.find_by_id(vid))
        unless v.fulfillment_needed
          flash[:notice] << "Warning: voucher ID #{vid} was already marked fulfilled<br/>"
        end
        v.fulfillment_needed = false
        v.save!
        i += 1
      end
    end
    redirect_to({:action => 'index'}, {:notice =>  "#{i} orders marked fulfilled"})
  end

  def revenue_by_payment_method
    # report may be by date range or by production
    if params[:txn_report_by] == 'date'
      from,to = Time.range_from_params(params[:txn_report_dates])
      return redirect_to(reports_path, :alert => 'Please select a date range of 3 months or less for the Revenue Details report.') if (to - from > 93.days)
      @report = RevenueByPaymentMethodReport.new.by_dates(from,to)
    else
      @report = RevenueByPaymentMethodReport.new.by_show_id(params[:txn_report_show_id])
    end
    return redirect_to(reports_path, :alert => @report.errors.as_html) unless @report.run
    if params[:commit] =~ /download/i # fall thru to screen display
      return ((csv = @report.csv) ?
        download_to_excel(@report.csv, 'revenue_details') :
        redirect_to(reports_path, :alert => @report.errors.as_html))
    end
  end

  def retail
    @from,@to = Time.range_from_params(params[:retail_report_dates])
    @items = RetailItem.
      joins(:order).
      where(:sold_on => @from..@to).
      order(:sold_on)
    return redirect_to(reports_path, :notice => 'No retail purchases match these criteria.') if @items.empty?
  end
  

  private

  def validate_report_type(str)
    klass = str.camelize.constantize
    valid = klass.ancestors.include?(Report)
    redirect_to(reports_path, :alert => "Invalid report name '#{str}'") unless valid
    valid && klass
  end

end
