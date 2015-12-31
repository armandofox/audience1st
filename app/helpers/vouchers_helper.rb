module VouchersHelper

  def comments_for_voucherlist(vouchers)
    comments = [ vouchers.first.order.comments ]
    comments += vouchers.map { |v| v.comments unless v.comments.blank? }
    comments.compact.uniq.join(";")
  end
end
