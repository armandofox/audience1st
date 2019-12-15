module VouchersHelper

  def comments_for_voucherlist(vouchers)
    comments = vouchers.map { |v| v.comments unless v.comments.blank? }
    comments.compact.uniq.join(";")
  end

  def errors_for_voucherlist_as_html(vouchers)
    vouchers.to_a.select { |item| !item.errors.empty? }.map { |item| item.errors.as_html }.join(', ')
  end
end
