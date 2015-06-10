class OrdersController < ApplicationController
  before_filter :is_boxoffice

  def index
    redirect_with(root_path, :alert => 'No customer specified') unless
      @customer = Customer.find_by_id(params[:customer_id])
    @orders = @customer.orders
    render :partial => 'order', :collection => @orders, :layout => true
  end

  def show
    @order = Order.find_by_id(params[:id])
    if @order.nil?
      flash[:alert] = "Order ID #{params[:id].to_i} not found"
      redirect_to customers_path
      return
    end
    @total = @order.total_price
    @refund_msg = "Upon refund, the customer's credit card charge will be reversed and all of these items will be permanently destroyed, which cannot be undone.  If the refund fails, all items will stay exactly as they are.  Do you want to proceed with the refund?" # "
    @printable = params[:printable]
    render :layout => 'layouts/receipt' if @printable
  end

  def destroy
    @order = Order.find params[:id]
    redirect_with(order_path(@order), :alert => 'This order is not refundable.') and return unless @order.refundable?
    total_amount = @order.total_price
    begin
      Order.transaction do
        Store.refund_credit_card(@order) if @order.purchase_medium == :credit_card
        Txn.add_audit_record(
          :txn_type => 'refund',
          :comments => @order.summary_for_audit_txn,
          :logged_in_id => current_user().id,
          :dollar_amount => total_amount,
          :order_id => @order.id)
        @order.destroy
      end
    rescue Stripe::StripeError => e
      redirect_with(order_path(@order), :alert => "Could not process credit card refund: #{e.message}")
      return
    rescue RuntimeError => e
      redirect_with(order_path(@order), :alert => "Error destroying order: #{e}")
      return
    end
    formatted_amount = sprintf("$%.2f", total_amount)
    notice =
      case @order.purchase_medium
      when :credit_card then "Credit card refund of #{formatted_amount} successfully processed."
      when :check then "Please destroy or return customer's original check for #{formatted_amount}."
      else "Please refund #{formatted_amount} in cash to customer."
      end
    redirect_with(customer_path(@order.customer), :notice => notice)
  end

end
