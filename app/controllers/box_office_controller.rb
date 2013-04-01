class BoxOfficeController < ApplicationController

  before_filter(:is_boxoffice_filter,
                :redirect_to => { :controller => :customers, :action => :login})

  # sets  instance variable @showdate and others for every method.
  before_filter :get_showdate, :except => [:mark_checked_in, :modify_walkup_vouchers]
  verify(:method => :post,
         :only => %w(do_walkup_sale modify_walkup_vouchers),
         :redirect_to => { :action => :walkup, :id => @showdate },
    :add_to_flash => {:warning => "Warning: action only callable as POST, no transactions were recorded! "})
  verify :method => :post, :only => :mark_checked_in
  ssl_required :walkup, :do_walkup_sale
  ssl_allowed :change_showdate
  
  private

  # this filter must setup @showdates (pulldown menu) and @showdate
  # (current showdate, to which walkup sales will apply), or if not possible to set them,
  # force a redirect to a different controller & action
  def get_showdate
    @showdates = Showdate.all_shows_this_season
    if @showdates.empty?
      flash[:notice] = "There are no shows this season eligible for check-in right now.  Please add some."
      redirect_to :controller => 'shows', :action => 'index'
    end
    @showdate = Showdate.find_by_id(params[:id]) ||
      Showdate.current_or_next(2.hours) ||
      @showdates.last
  end

  def vouchers_for_showdate(showdate)
    perf_vouchers = @showdate.advance_sales_vouchers
    total = perf_vouchers.size
    num_subscribers = perf_vouchers.select { |v| v.customer.subscriber? }.size
    vouchers = perf_vouchers.group_by do |v|
      "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
    end
    return [total,num_subscribers,vouchers]
  end

  public

  def index
    redirect_to :action => :walkup, :id => params[:id]
  end

  def change_showdate
    unless ((sd = params[:id].to_i) &&
            (showdate = Showdate.find_by_id(sd)))
      flash[:notice] = "Invalid show date."
    end
    redirect_to :action => 'walkup', :id => sd
  end

  def checkin
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
  end

  def mark_checked_in
    render :nothing => true and return unless params[:vouchers]
    vouchers = params[:vouchers].split(/,/).map { |v| Voucher.find_by_id(v) }.compact
    if params[:uncheck]
      vouchers.map { |v| v.un_check_in! }
    else
      vouchers.map { |v| v.check_in! }
    end
    render :update do |page|
      showdate = vouchers.first.showdate
      page.replace_html 'show_stats', :partial => 'show_stats', :locals => {:showdate => showdate}
      if params[:uncheck]
        vouchers.each { |v| page[v.id.to_s].removeClassName('checked_in') }
      else
        vouchers.each { |v| page[v.id.to_s].addClassName('checked_in') }
      end
    end
  end

  def door_list
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
    if @vouchers.empty?
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to :action => 'walkup', :id => @showdate
    else
      render :layout => 'door_list'
    end
  end

  def walkup
    @valid_vouchers = @showdate.valid_vouchers_for_walkup
    @admin = @gAdmin
    @qty = params[:qty] || {}     # voucher quantities
  end

  def do_walkup_sale
    @order = Order.new(
      :walkup => true,
      :customer => Customer.walkup_customer,
      :purchaser => Customer.walkup_customer,
      :processed_by => @gAdmin)
    if ((amount = params[:donation].to_f) > 0)
      @order.add_donation(Donation.walkup_donation amount)
    end
    ValidVoucher.from_params(params[:qty]).each_pair do |valid_voucher, qty|
      @order.add_tickets(valid_voucher, qty)
    end

    # process order using appropriate payment method.
    # if Stripe was used for credit card processing, it resubmits the original
    #  form to us, but doesn't correctly pass name of Submit button that was
    #  pressed, so we recover it here:
    params[:commit] ||= 'credit'

    case params[:commit]
    when /cash/i
      @order.purchasemethod = Purchasemethod.find_by_shortdesc(
        @order.total_price.zero? ? 'none' : 'box_cash')
    when /check/i
      @order.purchasemethod = Purchasemethod.find_by_shortdesc('box_chk')
      @order.purchase_args = {:check_number => params[:check_number]}
    else                      # credit card
      @order.purchasemethod = Purchasemethod.find_by_shortdesc('box_cc')
      @order.purchase_args = {:credit_card_token => params[:credit_card_token]}
    end
      
    flash[:warning] = 'There are no items to purchase.' if @order.item_count.zero?
    flash[:warning] ||= @order.errors.full_messages.join(', ') unless @order.ready_for_purchase?
    redirect_to(:action => 'walkup', :id => @showdate) and return if flash[:warning]

    # all set to try the purchase
    begin
      @order.finalize!
      Txn.add_audit_record(:txn_type => 'tkt_purch',
                           :customer_id => Customer.walkup_customer.id,
                           :comments => 'walkup',
                           :purchasemethod_id => p,
                           :logged_in_id => logged_in_id)
      flash[:notice] = "#{@order.item_count} tickets"
      flash[:notice] << " and #{@order.donation.amount}" if @order.include_donation?
      flash[:notice] << " as zero-revenue order" if @order.total_price.zero?
      flash[:notice] << " paid by #{@order.purchase_medium}"
      redirect_to :action => 'walkup', :id => @showdate
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError
      flash[:warning] = "Transaction NOT processed: " <<
        @order.errors.full_messages.join(', ')
      redirect_to :action => 'walkup', :id => @showdate, :qty => params[:qty], :donation => params[:donation]
    end
  end

  def walkup_report
    @vouchers = @showdate.walkup_vouchers.group_by(&:purchasemethod)
    @subtotal = {}
    @total = 0
    @vouchers.each_pair do |purch,vouchers|
      @subtotal[purch] = vouchers.map(&:price).sum
      @total += @subtotal[purch]
    end
    @other_showdates = @showdate.show.showdates
  end

  # process a change of walkup vouchers by either destroying them or moving them
  # to another showdate, as directed
  def modify_walkup_vouchers
    if params[:vouchers].blank?
      flash[:warning] = "You didn't select any vouchers to remove or transfer."
      redirect_to(:action => :index) and return
    end
    voucher_ids = params[:vouchers]
    action = params[:commit].to_s
    showdate_id = 0
    begin
      vouchers = Voucher.find(voucher_ids)
      showdate_id = vouchers.first.showdate_id
      if action =~ /destroy/i
        Voucher.destroy_multiple(vouchers, logged_in_user)
        flash[:notice] = "#{vouchers.length} vouchers destroyed."
      elsif action =~ /transfer/i # transfer vouchers to another showdate
        showdate = Showdate.find(params[:to_showdate])
        Voucher.transfer_multiple(vouchers, showdate, logged_in_user)
        flash[:notice] = "#{vouchers.length} vouchers transferred to #{showdate.printable_name}."
      else
        flash[:warning] = "Unrecognized action: '#{action}'"
      end
    rescue Exception => e
      flash[:warning] = "Error (NO changes were made): #{e.message}"
      RAILS_DEFAULT_LOGGER.warn(e.backtrace)
    end
    redirect_to :action => :index, :id => showdate_id
  end

end
