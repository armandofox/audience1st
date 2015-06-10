class OrdersController < ApplicationController
  before_filter :is_boxoffice

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

  def by_customer
    @customer = Customer.find params[:id]
    @orders = @customer.orders
    render :partial => 'order', :collection => @orders, :layout => true
  end

  def destroy
    redi
  end

end
