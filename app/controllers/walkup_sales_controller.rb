class WalkupSalesController < ApplicationController

  before_filter :is_boxoffice_filter

  def show
    @showdate = Showdate.find params[:id]
    @valid_vouchers = @showdate.valid_vouchers_for_walkup
    @admin = current_user
    @qty = params[:qty] || {}     # voucher quantities
  end

  def create
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
    flash[:alert] ||= @order unless @order.ready_for_purchase?
    redirect_to edit_boxoffice_path(@showdate) and return if flash[:alert]

    # all set to try the purchase
    begin
      @order.finalize!
      Txn.add_audit_record(:txn_type => 'tkt_purch',
        :customer_id => Customer.walkup_customer.id,
        :comments => 'walkup',
        :purchasemethod_id => p,
        :logged_in_id => current_user.id)
      flash[:notice] = @order.walkup_confirmation_notice
      redirect_to walkup_sales_path(@showdate)
    rescue Order::PaymentFailedError, Order::SaveRecipientError, Order::SavePurchaserError
      flash[:alert] = ["Transaction NOT processed: ", @order]
      redirect_to walkup_sales_path(@showdate, :qty => params[:qty], :donation => params[:donation])
    end
  end

  # process a change of walkup vouchers by moving them to another showdate, as directed
  def update
    @showdate = Showdate.find params[:id]
    redirect_with(walkup_sales_path(@showdate), :alert => "You didn't select any vouchers to transfer.") and return if params[:vouchers].blank?
    voucher_ids = params[:vouchers]
    showdate_id = 0
    begin
      vouchers = Voucher.find(voucher_ids)
      showdate_id = vouchers.first.showdate_id
      showdate = Showdate.find(params[:to_showdate])
      Voucher.change_showdate_multiple(vouchers, showdate, current_user)
      flash[:notice] = "#{vouchers.length} vouchers transferred to #{showdate.printable_name}."
    rescue Exception => e
      flash[:alert] = "Error (NO changes were made): #{e.message}"
      RAILS_DEFAULT_LOGGER.warn(e.backtrace)
    end
    redirect_to walkup_sales_path(@showdate)
  end

