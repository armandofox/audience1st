module OrdersHelper

  def link_to_order_containing(item)
    link_to item.order_id, order_path(item.order)
  end

  def deletion_warning_for(order)
    "This will remove all items in this order from patron's account" <<
      (order.purchase_medium == :credit_card ? " and refund their credit card" : "") <<
      ". OK to proceed?"
  end
end
