class DonationsController < ApplicationController

  before_filter :is_staff_filter
  before_filter :load_customer, :only => [:new, :create]

  private

  def load_customer
    return redirect_to(donations_path, :alert => 'You must select a customer.') unless @customer = Customer.find(params[:customer_id])
  end

  public
  
  def index
    @total = 0
    @params = {}
    @page_title = "Donation history"
    @page = (params[:page] || '1').to_i
    mindate,maxdate = params[:dates] ? Time.range_from_params(params[:dates]) : [Time.current.at_beginning_of_season,Time.current]
    params[:from],params[:to] = mindate,maxdate
    @donations = Donation.
      includes(:order,:customer,:account_code).
      where.not(:customer_id => Customer.walkup_customer.id).
      order('orders.sold_on')
    if params[:use_cid]
      cid = Customer.id_from_route(params[:cid])
      @donations = @donations.where(:customer_id => cid)
      @full_name = Customer.find(cid).full_name
    end
    if params[:use_date]
      @donations = @donations.where('orders.sold_on' => mindate..maxdate)
    end
    if params[:use_amount]
      @donations = @donations.where(:amount => params[:donation_min].to_f .. params[:donation_max].to_f)
    end
    if params[:use_ltr_sent]
      @donations = @donations.where(:letter_sent => nil)
    end
    if params[:use_fund] && !params[:donation_funds].blank?
      @donations = @donations.where(:account_code_id => params[:donation_funds])
    end
    @total = @donations.sum(:amount)
    @export_label = "Download in Excel Format"
    @params = params
    if params[:commit] == @export_label
      send_data @donations.to_csv,  :type => 'text/csv', :filename => filename_from_dates('donations',mindate,maxdate,'csv')
    else
      @donations = @donations.paginate(:page => @page)
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
      @order.purchasemethod = Purchasemethod.get_type_by_name('box_chk')
    when 'cash'
      @order.purchasemethod = Purchasemethod.get_type_by_name('box_cash')
    when 'credit_card'
      @order.purchasemethod = Purchasemethod.get_type_by_name('box_cc')
      @order.purchase_args =  { :credit_card_token => params[:credit_card_token] }
      sold_on = Time.current
    end
    @order.comments = params[:comments].to_s
    unless @order.ready_for_purchase?
      flash[:alert] = @order.errors.as_html
      render :action => 'new'
      return
    end
    begin
      @order.finalize!(sold_on)
      redirect_to(customer_path(@customer), :notice => 'Donation recorded.')
    rescue Order::PaymentFailedError => e
      redirect_to(new_customer_donation_path(@customer), :alert => e.message)
    rescue StandardError => e
      # rescue ActiveRecord::RecordInvalid => e
      # rescue Order::OrderFinalizeError => e
      # rescue RuntimeError => e
    end
  end

  def update
    if (t = Donation.find_by_id(params[:id])).kind_of?(Donation)
      now = Time.current
      c = current_user.email rescue "(??)"
      t.update_attributes(:letter_sent => now,
        :processed_by => current_user)
      Txn.add_audit_record(:cust_id => t.customer_id,
        :logged_in_id => current_user.id,
        :txn_type => 'don_ack',
        :comments => "Donation ID #{t.id} marked as acknowledged")
      result = now.strftime("%D by #{c}")
    else
      result = '(ERROR)'
    end
    render :js => %Q{\$('#donation_#{params[:id]}').text('#{result}')}
  end
  
end
