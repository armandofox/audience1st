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
    if !params[:dates].blank?
      mindate,maxdate = Time.range_from_params(params[:dates])
      @header = "#{mindate.to_formatted_s(:compact)}-#{maxdate.to_formatted_s(:compact)}: "
    else
      mindate,maxdate = [Time.parse("2007-01-01"), Time.current]
      @header = ''
    end
    @donations = Donation.
      includes(:order,:customer,:account_code).
      where.not(:customer_id => Customer.walkup_customer.id).
      order(:sold_on)
    if params[:use_cid]         # cust id will be embedded in route in autocomplete field
      cid = if params[:cid] =~ /^\d+$/ then params[:cid] else Customer.id_from_route(params[:cid]) end
      @donations = @donations.where(:customer_id => cid)
      @full_name = Customer.find(cid).full_name
    end
    if params[:use_date]
      @donations = @donations.where(:sold_on => mindate..maxdate)
    end
    if params[:use_amount]
      @donations = @donations.where(:amount => params[:donation_min].to_f .. params[:donation_max].to_f)
    end
    if params[:use_ltr_sent]
      @donations = @donations.where(:letter_sent => nil)
    end
    if !params[:use_fund].blank? && !params[:donation_funds].blank?
      @donations = @donations.where(:account_code_id => params[:donation_funds])
    end
    @total = @donations.sum(:amount)
    @params = params

    if params[:commit] =~ /download/i
      send_data @donations.to_csv,  :type => 'text/csv', :filename => 'donations_report.csv'
    else
      @donations = @donations.paginate(:page => @page)
      @header << "#{@donations.total_entries} transactions, " <<
        ActionController::Base.helpers.number_to_currency(@total)
    end
  end

  def new
    @donation ||= @customer.donations.new(:amount => 0,:comments => '')
  end

  def create
    @order = Order.create(:purchaser => @customer, :customer => @customer, :processed_by => current_user)
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
      @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
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
      @order.destroy
      redirect_to(new_customer_donation_path(@customer), :alert => e.message)
    rescue StandardError => e
      @order.destroy
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
      Txn.add_audit_record(:customer_id => t.customer_id,
        :logged_in_id => current_user.id,
        :txn_type => 'don_ack',
        :comments => "Donation ID #{t.id} marked as acknowledged")
      result = now.strftime("%D by #{c}")
    else
      result = '(ERROR)'
    end
    render :js => %Q{\$('#donation_#{params[:id]}').text('#{result}')}
  end

  # AJAX handler for updating the text of a donation's comment
  def update_comment_for
    begin
      donation = Donation.find(params[:id])
      comments = params[:comments]
      donation.update_attributes!(:comments => comments)
      Txn.add_audit_record(:customer_id => donation.customer_id, :logged_in_id => current_user.id,
        :order_id => donation.order_id,
        :comments => comments,
        :txn_type => "don_edit")
      # restore "save comment" button to look like a check mark
      render :js => %Q{alert('Comment saved')}
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      error = ActionController::Base.helpers.escape_javascript(e.message)
      render :js => %Q{alert('There was an error saving the donation comment: #{error}')}
    end
  end
end
