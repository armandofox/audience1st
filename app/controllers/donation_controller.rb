class DonationController < ApplicationController

  before_filter :is_staff_filter, :only => %w[new create], :redirect_to => {:controller => 'customers', :action => 'login' }
  before_filter :is_boxoffice_manager_filter, :except => %w[new create]
  verify(:method => :post, :only => %w[create mark_ltr_sent],
         :add_to_flash => "System error: method should only be called via POST",
         :redirect_to => {:action => 'list'})

  scaffold :donation
  
  def list
    unless params[:commit]
      # first time visiting page: don't do "null search"
      @things = []
      @params = {}
      render :action => 'list'
      return
    end
    #query = QueryBuilder.new("SELECT DISTINCT d.* FROM Donations d, Customers c WHERE ")
    conds = {}
    if (params[:use_cid] &&
        (cid = params[:cid].to_i) != 0) &&
        (c = Customer.find_by_id(cid))
      @page_title = "Donation history: #{c.full_name}"
      flash[:notice] = "Search restricted to customer #{c.full_name}"
      conds.merge!("customer_id = ?" => cid)
    else
      @page_title = "Donation history"
    end
    if params[:from]
      params[:from] = mindate = Time.local(*([:year,:month,:day].map { |x| params[:from][x] }))
    end
    if params[:to]
      params[:to] = maxdate = Time.local(*([:year,:month,:day].map { |x| params[:to][x] }))
    end
    if params[:use_date]
      mindate,maxdate = maxdate,mindate if mindate > maxdate
      conds.merge!("date >= ?" => mindate, "date <= ?" => maxdate)
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
    keys = conds.keys
    conds_array = ([keys.join(" AND ")] + keys.map { |k| conds[k] }).compact
    if conds.empty?
      @things = Donation.find(:all)
    else
      @things = Donation.find(:all, :conditions => conds_array)
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
                                     x.date : x.showdate.thedate.date_part) }
    @export_label = "Download in Excel Format"
    @params = params
    if params[:commit] == @export_label
      export(@things.select { |thing| thing.kind_of?(Donation) })
    end
  end

  def mark_ltr_sent
    id = params[:id]
    if (t = Donation.find_by_id(params[:id])).kind_of?(Donation)
      now = Time.now
      c = Customer.find(logged_in_id).login rescue "(ERROR)"
      t.update_attributes(:letter_sent => now,
                          :processed_by => logged_in_id)
      Txn.add_audit_record(:cust_id => t.customer_id,
                           :logged_in_id => logged_in_id,
                           :txn_type => 'don_ack',
                           :comments => "Donation ID #{t.id} marked as acknowledged")
      render :text => "#{now.strftime("%D")} by #{c}"
    else
      render :text => "(ERROR)"
    end
  end
  
  def new
    unless @cust = Customer.find_by_id(params[:customer])
      flash[:notice] = "Must select a customer to add a donation"
      redirect_to :controller => 'customers', :action => 'list'
      return
    end
    @donation = Donation.new({'customer_id' => params[:customer]})
  end

  def create
    @donation = Donation.new(params[:donation])
    unless (c = Customer.find_by_id(@donation.customer.id))
      flash[:notice] = "Select a customer to add a donation"
      redirect_to :controller => 'customers', :action => 'list'
      return
    end
    if @donation.save
      c.donations << @donation
      flash[:notice] = sprintf("Donation of value $%.2f added for customer #{@donation.customer.full_name}", @donation.amount)
      redirect_to :action => 'list'
    else
      flash[:notice] = "Errors occurred, donation was NOT recorded"
      @cust = c
      render :action=>'new', :customer=>c
    end
  end
      
  private

  def export(donations)
    content_type = (request.user_agent =~ /windows/i ? 'application/vnd.ms-excel' : 'text/csv')
    CSV::Writer.generate(output = '') do |csv|
      csv << %w[last first street city state zip amount date code fund letterSent]
      donations.each do |d|
        csv << [d.customer.last_name.name_capitalize,
                d.customer.first_name.name_capitalize,
                d.customer.street,
                d.customer.city,
                d.customer.state,
                d.customer.zip,
                d.amount,
                d.date.to_formatted_s(:db),
                d.account_code,
                d.donation_fund.name,
                d.letter_sent]
      end
      send_data(output, :type => content_type,
                :filename => "donations_#{Time.now.strftime('%Y_%m_%d')}.csv")
    end
  end
  
end
