module OrdersHelper

  def link_to_order_containing(item)
    link_to item.order_id, order_path(item.order)
  end

  def deletion_warning_for(order)
    "Delete checked items" <<
      (order.purchase_medium == :credit_card ? " and issue credit card refund?" : "?")
  end

  def one_line_order_summary(order)
    "Order ##{order.id} processed by #{staff_name(order.processed_by)} on #{order.sold_on.to_formatted_s :showtime_including_year}".html_safe
  end
end
