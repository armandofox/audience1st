class WalkupSalesController < ApplicationController

  before_filter :is_boxoffice_filter

  before_action do
    @showdate = Showdate.in_theater.find params[:id]
    @page_title = "Walkups: #{@showdate.thedate.to_formatted_s(:foh)}"
    if @showdate.has_reserved_seating?
      @seatmap_info = Seatmap.seatmap_and_unavailable_seats_as_json(@showdate)
    end
  end
  
  include SeatmapsHelper

  def show
    all_valid_vouchers = @showdate.valid_vouchers_for_walkup
    (@nonticket_items, @valid_vouchers) = all_valid_vouchers.partition { |vv| vv.vouchertype.nonticket? }.map(&:to_a)
    @admin = current_user
    @qty = params[:qty] || {}     # voucher quantities
    @nonticket = params[:nonticket] || {} # retail item quantities
    @donation = params[:donation]
    @seats = params[:seats]
    # if reserved seating show, populate hidden field
  end

  def create
    @order = Order.create(
      :walkup => true,
      :customer => Customer.walkup_customer,
      :purchaser => Customer.walkup_customer,
      :processed_by => current_user)
    if ((donation = params[:donation].to_f) > 0)
      @order.add_donation(Donation.walkup_donation donation)
    end
    nonticket = params[:nonticket]
    @order.add_nonticket_items_from_params(nonticket)
    seats = seats_from_params(params)
    qtys = params[:qty]
    @order.add_tickets_from_params(qtys, current_user, :seats => seats)
    saved_params = {:qty => qtys, :nonticket => nonticket, :donation => donation,
      :seats => display_seats(seats)} # in case have to retry
    return redirect_to(walkup_sale_path(@showdate,saved_params), :alert => t('store.errors.empty_order')) if
      (donation.zero? && @order.vouchers.empty? && @order.retail_items.empty?)

    # process order using appropriate payment method.
    # if Stripe was used for credit card processing, it resubmits the original
    #  form to us, but doesn't correctly pass name of Submit button that was
    #  pressed, so we recover it here:
    params[:commit] ||= 'credit'

    case params[:commit]
    when /cash/i
      @order.purchasemethod = Purchasemethod.get_type_by_name(
        @order.total_price.zero? ? 'none' : 'box_cash')
    when /check/i
      @order.purchasemethod = Purchasemethod.get_type_by_name('box_chk')
      @order.purchase_args = {:check_number => params[:check_number]}
    else                      # credit card
      @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
      @order.purchase_args = {:credit_card_token => params[:credit_card_token]}
    end
    
    return redirect_to(walkup_sale_path(@showdate, saved_params), :alert => "Cannot complete order: #{@order.errors.as_html}") unless @order.errors.empty?

    # all set to try the purchase
    begin
      # walkup sales should automatically be checked in
      @order.vouchers.map(&:check_in!)
      @order.finalize!
      Txn.add_audit_record(:txn_type => 'tkt_purch',
        :customer_id => Customer.walkup_customer.id,
        :comments => 'walkup',
        :purchasemethod => p,
        :logged_in_id => current_user.id)
      flash[:notice] = @order.walkup_confirmation_notice
      flash[:notice] << ". Seats: #{params[:seats]}" unless params[:seats].blank?
      redirect_to walkup_sale_path(@showdate)
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError, Order::NotReadyError
      flash[:alert] = "Transaction NOT processed: #{@order.errors.as_html}"
      @order.destroy
      redirect_to walkup_sale_path(@showdate, saved_params)
    end
  end

  # process a change of walkup vouchers by moving them to another showdate, as directed
  def update
    return redirect_to(walkup_sale_path(@showdate), :alert => "You didn't select any vouchers to transfer.") if params[:vouchers].blank?
    voucher_ids = params[:vouchers]
    begin
      vouchers = Voucher.find(voucher_ids)
      showdate = Showdate.find(params[:to_showdate])
      Voucher.change_showdate_multiple(vouchers, showdate, current_user)
      flash[:notice] = "#{vouchers.length} vouchers transferred to #{showdate.printable_name}."
    rescue ActiveRecord::RecordNotFound, RuntimeError => e
      flash[:alert] = "Error (NO changes were made): #{e.message}"
    end
    redirect_to walkup_sale_path(@showdate)
  end

  def report
    @vouchers = @showdate.walkup_vouchers.group_by(&:purchasemethod)
    @subtotal = {}
    @total = 0
    @vouchers.each_pair do |purch,vouchers|
      @subtotal[purch] = vouchers.map(&:amount).sum
      @total += @subtotal[purch]
    end
    @other_showdates = @showdate.show.showdates.reject { |s| s.has_reserved_seating? } - [@showdate]
  end

end
