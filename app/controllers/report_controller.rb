class ReportController < ApplicationController

  include Enumerable
  require 'set'
  
  before_filter :is_staff_filter
  before_filter(:is_boxoffice_manager_filter,
                :only => %w[customer_list])

  def index
    # all showdates
    @all_showdates = Showdate.find_all.sort_by { |s| s.thedate }
    # next showdate
    @next_showdate = @all_showdates.detect { |s| s.thedate >= Time.now }
    # all show names
    @all_shows = Show.find_all
    # quick subscription stats
    @subscriptions = subscription_vouchers(Time.now.year)
  end

  verify(:method => :post, :only => %w[noshow_subscriber mark_fulfilled],
         :add_flash => {:notice => 'ERROR: Action can only be called via POST'})

  def advanced_customer_list
    @show_names = Show.find_all
    @vouchertypes =
      Vouchertype.find(:all, :conditions => ["is_bundle = ?", false])
    @bundle_vouchertypes =
      Vouchertype.find(:all, :conditions => ["is_bundle = ?", true])
    return unless params[:commit]
    # process the query...
    sql = QueryBuilder.new("SELECT DISTINCT c.* FROM customers c, vouchers v")
    sql.add_clause("c.id=v.customer_id")
    sql.add_clause("c.role >= 0")
    if params[:restrict_by_date]
      d = params[:date]
      date = Time.local(d[:year],d[:month],d[:day])
      case params[:date_how]
      when /^added since/i
        sql.add_clause("c.created_on >= ?", date)
      when /^added before/i
        sql.add_clause("c.created_on < ?", date)
      when /^updated since/i
        sql.add_clause("c.updated_on >= ?", date)
      when /^not updated since/i
        sql.add_clause("c.updated_on < ?", date)
      when /^logged in since/i
        sql.add_clause("c.last_login >= ?", date)
      when /^not logged in since/i
        sql.add_clause("c.last_login < ?", date)
      end
    end
    if params[:restrict_by_email]
      sql.add_clause((params[:restrict_by_email_how].blank? ?
                      "c.login NOT LIKE ?" : "c.login LIKE ?"), "%@%%.%")
    end
    if params[:restrict_by_snailmail]
      sql.add_clause((params[:restrict_by_snailmail_how].blank? ?
                      "c.street IS NULL OR c.street = ?" :
                      "c.street IS NOT NULL AND c.street != ?"), "")
    end
    # restrict_by_voucher and restrict_by_bundle must be handled together.
    # restrict_by_voucher requires that the showdate_id be zero, while
    # restrict_by_bundle doesn't.  if both are present we must do an OR.
    clauses = []
    if params[:restrict_by_voucher]
      v_types = Array.new(params[:voucher_types].length,"v.vouchertype_id = ?").join(" OR ")
      clauses << "(v.showdate_id = 0 AND (#{v_types}))"
      
    end
    if params[:restrict_by_bundle_voucher]
      vt_types = Array.new(params[:bundle_voucher_types].length,"v.vouchertype_id = ?").join(" OR ")
      clauses << "(#{vt_types})"
    end
    unless clauses.empty?
      sql.add_clause("(" << clauses.join(" OR ") << ")",
                     *((params[:voucher_types]+params[:bundle_voucher_types]).map {|v| v.to_i}))
    end
    @sql = sql.render_sql
    @results = Customer.find_by_sql(sql.sql_for_find)
    # postprocessing - stuff that can't easily be done in the join
    # subscribers, nonsubscribers, or all?
    if params[:subscribers] =~ /^non/i
      @results.reject { |c| c.is_subscriber? }
    elsif params[:subscribers] =~ /^subscriber/i
      @results.select { |c| c.is_subscriber? }
    end
    # seen all, any, none of these shows?
    if params[:restrict_by_show]
      selected_shows = params[:shows].map { |s| Show.find(s) }
      case params[:restrict_by_show_how]
      when /all/i
        @results.reject! { |c| !(c.shows.to_set.subset?(selected_shows.to_set)) }
      when /none/i
        @results.reject! { |c| selected_shows.any? { |s| c.shows.include?(s) }}
      when /any/i
        @results.reject! { |c| !(selected_shows.any? { |s| c.shows.include?(s) })}
      end
    end
    @params = params
  end

  def customer_list
    order_by = (params[:sort_by_zip] ? 'zip, last_name' : 'last_name, zip')
    if params[:subscribers_only]
      @c = Customer.find(:all, :order => order_by, :include => :vouchers)
      @c.delete_if { |c| !c.is_subscriber? }
    else
      @c = Customer.find(:all, :order => order_by)
    end
    @total = @c.length
    # remove invalid addresses
    @c.delete_if { |cst| cst.invalid_mailing_address? } if params[:filter_invalid_addresses]
    remove_dup_addresses(@c) if params[:remove_dups]
    @selected = @c.length
    export_customers_to_excel(@c)
  end

  def advance_sales
    case params[:showdate_id]
    when /current/i
      @shows = [Show.find(:first, :conditions => ['closing_date >= ?', Date.today], :order => 'opening_date')]
    when /^(\d+)$/
      @shows = [Show.find_by_id($1)]
    when /future/i 
      @shows = Show.find(:all, :conditions => ['closing_date >= ?', Date.today], :order => 'opening_date')
    else
      @shows = Show.find(:all,:order => 'opening_date')
    end
    if (@shows.empty? rescue nil)
      flash[:notice] = "No shows match your critera"
      redirect_to :action => 'index'
      return
    end
  end

  def showdate_sales
    render :partial => 'showdate_sales', :locals => {:vouchers =>
      Object.const_get(params[:klass]).find(params[:id]).vouchers.group_by(&:vouchertype) }
  end

  def sales_detail
    from = Time.local(*([:year,:month,:day].map { |x| params[:from][x] }))
    to = Time.local(*([:year,:month,:day].map { |x| params[:to][x] }))
    from,to = to,from if from > to
    from = from.midnight
    to = (to+1.day).midnight
    conds = ["customer_id != 0",
             "(showdate_id > 0 OR (vouchertype.is_bundle=1 AND vouchertype.is_subscription=1))",
             "sold_on BETWEEN ? AND ?"]
    conds = [conds.join(" AND "), from, to]
    sql = ["SELECT DISTINCT v.* FROM vouchers v,vouchertypes vt WHERE " <<
           "(v.sold_on BETWEEN ? AND ?) AND " <<
           "v.customer_id !=0 AND " <<
           "(v.showdate_id > 0 OR (v.vouchertype_id = vt.id AND vt.is_bundle=1 AND vt.is_subscription=1))", from, to]
    sales = Voucher.find_by_sql(sql)
    #sales = Voucher.find(:all,:include => :vouchertype,:conditions => conds)
    @nsales = sales.size
    @page_title = "#{@nsales} Transactions: #{from.strftime('%a %b %e')} " <<
      (to - from > 1.day ? (" - " << to.strftime('%a %b %e')) : '')
    @daily_sales = sales.group_by do |v|
      u = v.sold_on
      "#{u.change(:min => u.min - u.min.modulo(3))},#{v.customer.last_name},#{v.customer.first_name},#{v.vouchertype_id},#{v.processed_by}"
    end
    @nunique = sales.group_by { |v| v.customer.id }.keys.size
    if @daily_sales.empty?
      flash[:notice] = "No transactions during date range given"
      redirect_to :action => 'index'
      return
    end
  end

  def accounting_report
    @from = Time.local(*([:year,:month,:day].map { |x| params[:from][x] }))
    @to = Time.local(*([:year,:month,:day].map { |x| params[:to][x] }))
    @from,@to = @to,@from if @from > @to
    @from = @from.midnight
    @to = (@to+1.day).midnight
    # get all vouchers sold between these dates where:
    #  - NOT walkup sales
    #  - purchasemethod is some credit card transaction
    #  - vouchertype has a price > 0
    purchasemethods = params[:purchasemethods].map { |x| x.to_i } * ","
    # run report for all vouchertypes such that:
    # - account code is not null
    # - price > 0
    vouchertypes = Vouchertype.find(:all, :conditions =>
                                    "account_code IS NOT NULL AND price > 0")
    acc_codes = vouchertypes.map { |vt| vt.account_code }
    @vtypes_for_acc_code = {}
    vouchertypes.group_by(&:account_code).each_pair do |k,v|
      @vtypes_for_acc_code[k] = "alert('" <<
        v.map { |vt| vt.name }.join(", ")  << "')"
    end
    # for each account code, find all vouchers sold for each show
    @txns = {}
    @total = 0.0
    sh = Showdate.find(:all).group_by(&:show_id)
    acc_codes.each do |acc|
      sh.each_pair do |show_id, showdate_id_list|
        showdate_ids = showdate_id_list.map { |x| x.id }.join(",")
        sql = ["SELECT SUM(vt.price) " <<
               "FROM vouchers v INNER JOIN vouchertypes vt ON v.vouchertype_id = vt.id WHERE " <<
               "(v.sold_on BETWEEN ? and ?) AND " <<
               "vt.account_code = ? AND " <<
               "v.showdate_id IN (#{showdate_ids}) AND " <<
               "v.customer_id != 0 AND v.customer_id != ? AND " <<
               "(v.purchasemethod_id IN (#{purchasemethods}))",
               @from, @to, acc, Customer.walkup_customer.id]
        result = Voucher.find_by_sql(sql)
        ttl = result[0]["SUM(vt.price)"].to_i
        @txns["#{show_id},#{acc}"] = ttl unless ttl.zero?
        @total += ttl
      end
    end
  end

  def subscriber_details
    y = (params[:year] || Time.now.year).to_i
    subs = subscription_vouchers(y)
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

  def unfulfilled_orders
    @vouchers = Voucher.find(:all, :conditions => 'fulfillment_needed = 1')
    if @vouchers.empty?
      flash[:notice] = 'No unfulfilled orders at this time.'
      redirect_to :action => 'index'
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

  def boxoffice_report
    @showdate = Showdate.find(params[:showdate_id], :include => :vouchers)
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
      redirect_to :action => 'index'
    end
  end

  def walkup_sales
    sd = params[:showdate_id]
    unless (sd.to_i > 0) && (@showdate = Showdate.find_by_id(sd))
      flash[:notice] = "Walkup sales report requires valid showdate ID"
      redirect_to :action => 'index'
      return
    end
    @cash_tix = @showdate.vouchers.find_all_by_purchasemethod_id(Purchasemethod.get_type_by_name('walk_cash'))
    @cc_tix = @showdate.vouchers.find_all_by_purchasemethod_id(Purchasemethod.get_type_by_name('walk_cc'))
    @cash_tix_types = {}
    @cash_tix.each do |v|
      @cash_tix_types[v.vouchertype] ||= 0
      @cash_tix_types[v.vouchertype] += 1
    end
    @cc_tix_types = {}
    @cc_tix.each do |v|
      @cc_tix_types[v.vouchertype] ||= 0
      @cc_tix_types[v.vouchertype] += 1
    end
  end
  
  private

  def subscription_vouchers(year)
    season_start = Time.local(year,APP_CONFIG[:season_start_month].to_i)
    v = Vouchertype.find(:all, :conditions =>"is_bundle=1 AND is_subscription=1 AND name LIKE '%#{year}%'")
    #valid_date>=? AND expiration_date<?',season_start, season_start + 1.year])
    v.map { |t| [t.name, t.price.round, Voucher.count(:all, :conditions => "vouchertype_id = #{t.id}")] }
  end

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
  
  def remove_dup_addresses(arr)
    # remove duplicate addresses - based on case-insensitive match of street, whitespace squeezed
    # TBD this should be done with Array.uniq
    hshtemp = Hash.new
    arr.each_index do |i|
      canonical = arr[i].street.downcase.tr_s(' ', ' ')
      if hshtemp.has_key?(canonical)
        arr.delete_at(i)
      else
        hshtemp[canonical] = true
      end
    end
  end
end
