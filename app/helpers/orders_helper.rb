module OrdersHelper

  def link_to_order_containing(item)
    link_to item.order_id, order_path(item.order)
  end

end
