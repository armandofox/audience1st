module VouchersHelper

  def comments_for_voucherlist(vouchers)
    comments = vouchers.map { |v| v.comments unless v.comments.blank? }
    comments.unshift(vouchers.first.order.comments) if vouchers.first.order
    comments.compact.uniq.join(";")
  end
end
