module VouchersHelper

  def comments_for_voucherlist(vouchers)
    vouchers.map { |v| v.comments unless v.comments.blank? }.compact.uniq.join(";")
  end
end
