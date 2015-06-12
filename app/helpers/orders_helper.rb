module OrdersHelper

  def link_to_order_containing(item)
    link_to item.order_id, order_path(item.order)
  end

  def deletion_warning_for(order)
    "Delete checked items" <<
      (order.purchase_medium == :credit_card ? " and issue credit card refund?" : "?")
  end
end
