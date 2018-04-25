class OrdersController < ApplicationController
  before_filter :is_boxoffice_filter

  def index
    @customer = Customer.find params[:customer_id]
    return redirect_to(root_path, :notice => "#{@customer.full_name} has no orders.") if
      (@orders = @customer.orders.for_customer_reporting).empty?
  end

  def show
    @order = Order.where(:id => params[:id]).includes(:vouchers => [:showdate,:vouchertype]).first
    if @order.nil?
      flash[:alert] = "Order ID #{params[:id].to_i} not found"
      redirect_to customers_path
      return
    end
    @total = @order.total_price
    @printable = params[:printable]
    render :layout => 'layouts/receipt' if @printable
  end

  def update
    @order = Order.find params[:id]
    items = Item.find(params[:items].keys) rescue []
    if items.empty?
      redirect_to(order_path(@order), :alert => 'No items selected for refund.') and return
    elsif items.any? { |i| i.order_id != @order.id }
      redirect_to(order_path(@order), :alert => 'Some items not part of this order.') and return
    elsif items.any? { |i| !i.cancelable? }
      redirect_to(order_path(@order), :alert => 'Some items are not refundable.') and return
    end
    amount_to_refund = items.map(&:amount).sum
    by_whom = current_user()
    begin
      Item.transaction do
        items.each do |item|
          Txn.add_audit_record(
            :txn_type => 'refund',
            :comments => item.description_for_audit_txn,
            :logged_in_id => current_user().id,
            :dollar_amount => item.amount,
            :order_id => @order.id)
          item.cancel!(by_whom)
        end
        Store.refund_credit_card(@order, amount_to_refund) if @order.purchase_medium == :credit_card
      end
    rescue Stripe::StripeError => e
      redirect_to(order_path(@order), :alert => "Could not process credit card refund: #{e.message}") and return
    rescue RuntimeError => e
      redirect_to(order_path(@order), :alert => "Error destroying order: #{e}") and return
    end
    formatted_amount = sprintf("$%.2f", amount_to_refund)
    notice =
      case @order.purchase_medium
      when :credit_card then "Credit card refund of #{formatted_amount} successfully processed."
      when :check then "Please destroy or return customer's original check for #{formatted_amount}."
      else "Please refund #{formatted_amount} in cash to customer."
      end
    redirect_to(order_path(@order), :notice => notice)
  end

end
