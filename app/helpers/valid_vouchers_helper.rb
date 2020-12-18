module ValidVouchersHelper
  def humanize_sales_limit(limit)
    case limit
    when 0 then "0"
    when ValidVoucher::INFINITE then "&infin;".html_safe
    else limit.to_s
    end
  end
end
