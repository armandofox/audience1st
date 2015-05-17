class ReportsController < ApplicationController

  require 'set'

  before_filter :is_staff_filter

  def index
    # all showdates
    @all_showdates = Showdate.find(:all).sort_by { |s| s.thedate }
    # next showdate
    @next_showdate = Showdate.current_or_next
    # all show names
    @all_shows = Show.find(:all)
    # quick subscription stats
    @subscriptions = Voucher.subscription_vouchers(Time.now.year)
    # list of all special reports
    @special_report_names =
      Dir.entries("#{RAILS_ROOT}/app/models/reports/").select { |x| x.gsub!(/\.rb$/,'') }
  end

  def do_report
    # this is a dispatcher that just redirects to the correct report
    # based on a dropdown menu.
    case params[:rep]
    when /retail/i
      retail
    when /transaction/i
      transaction_details_report
    when /unearned/i
      redirect_to({:action => :index}, {:alert => "Improved donations/unearned revenue report coming soon.  In the meantime please click Donation tab and use the Donation Search function."})
    when /earned/i
      accounting_report
    else
      redirect_to({:action => 'index'}, {:notice => "Please select a valid report."})
    end
  end

  def advance_sales
    if (params[:shows].blank? ||
        (@shows = params[:shows].map { |s| Show.find_by_id(s) }.flatten).empty?)
      flash[:alert] = "Please select one or more shows."
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

  def transaction_details_report
    @from,@to = Time.range_from_params(params[:from],params[:to])
    @report = TransactionDetailsReport.run(@from, @to)
    redirect_to({:action => 'index'}, {:notice => 'No matching transactions found'}) and return if @report.empty?
    case params[:format]
    when /csv/i
      send_data(@report.to_csv,
        :type => (request.user_agent =~ /windows/i ? 'application/vnd.ms-excel' : 'text/csv'),
        :filename => filename_from_dates('transactions', @from, @to, 'csv'))
    when /pdf/i
      send_data(@report.to_pdf,
        :type => 'application/pdf',
        :filename => filename_from_dates('transactions', @from, @to, 'pdf'))
    else
      render :action => 'transaction_details_report'
    end
  end

  def accounting_report
    temporarily_unavailable; return
    @from,@to = Time.range_from_params(params[:from],params[:to])
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

  def retail
    @from,@to = Time.range_from_params(params[:from],params[:to])
    @items = RetailItem.find(:all,
      :include => :order,
      :conditions => ['orders.sold_on BETWEEN ? and ?', @from, @to],
      :order => 'orders.sold_on')
    redirect_to({:action => :index},
      {:notice => 'No retail purchases match these criteria.'}) and return if @items.empty?
  end
  
  def subscriber_details
    y = (params[:id] || Time.now.year).to_i
    subs = Voucher.subscription_vouchers(y)
    render :partial => 'subscriptions', :object => subs, :locals => {:year => y}
    if params[:download]
      CSV::Writer.generate(output='') do |csv|
        csv << %w[name amount quantity]
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
    @report = n.camelize.constantize.__send__(:new, params[:output])
    redirect_to({:action => :index}, {:alert => 'Unknown report name'}) and return if
      (n.blank? || @report.nil? || !@report.kind_of?(Report))
    result = @report.generate_and_postprocess(params) # error!
    unless result
      respond_to do |wants|
        wants.html {
          redirect_to({:action => 'index'}, {:alert => "Errors generating report: #{@report.errors}"})
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
        when /display/i
          @customers = @report.customers
          render :template => 'customers/list'
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
                     :include => [:customer, :vouchertype],
                     :conditions => 'items.fulfillment_needed = 1',
                     :order => "customers.last_name")
    redirect_to({:action => 'index'}, {:notice => 'No unfulfilled orders at this time.'}) and return if v.empty?
    if params[:csv]
      output = Voucher.to_csv(v)
      download_to_excel(output, 'customers')
    else
      @vouchers = v
      @unique_addresses = v.group_by { |vc| vc.customer.street }.keys.length
    end
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
    redirect_to({:action => 'index'}, {:notice =>  "#{i} orders marked fulfilled"})
  end

end
