class WalkupSalesController < ApplicationController

  before_filter :is_boxoffice_filter

  def show
    @showdate = Showdate.find params[:id]
    @valid_vouchers = @showdate.valid_vouchers_for_walkup
    @admin = current_user
    @qty = params[:qty] || {}     # voucher quantities
    @donation = params[:donation]
  end

  def create
    @showdate = Showdate.find params[:id]
    @order = Order.new(
      :walkup => true,
      :customer => Customer.walkup_customer,
      :purchaser => Customer.walkup_customer,
      :processed_by => current_user)
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
    
    flash[:alert] = 'There are no items to purchase.' if @order.item_count.zero?
    flash[:alert] ||= @order.errors.as_html unless @order.ready_for_purchase?
    return redirect_to(walkup_sale_path(@showdate)) if flash[:alert]

    # all set to try the purchase
    begin
      @order.finalize!
      Txn.add_audit_record(:txn_type => 'tkt_purch',
        :customer_id => Customer.walkup_customer.id,
        :comments => 'walkup',
        :purchasemethod_id => p,
        :logged_in_id => current_user.id)
      flash[:notice] = @order.walkup_confirmation_notice
      redirect_to walkup_sale_path(@showdate)
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError
      flash[:alert] = ["Transaction NOT processed: ", @order.errors.as_html]
      redirect_to walkup_sale_path(@showdate, :qty => params[:qty], :donation => params[:donation])
    end
  end

  # process a change of walkup vouchers by moving them to another showdate, as directed
  def update
    @showdate = Showdate.find params[:id]
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
    @showdate = Showdate.find params[:id]
    @vouchers = @showdate.walkup_vouchers.group_by(&:purchasemethod)
    @subtotal = {}
    @total = 0
    @vouchers.each_pair do |purch,vouchers|
      @subtotal[purch] = vouchers.map(&:amount).sum
      @total += @subtotal[purch]
    end
    @other_showdates = @showdate.show.showdates
  end

end
