module VouchersHelper

  def vouchers_sorted_by_seat(list)
    list.sort_by(&:seat).map do |v|
      if v.customer             # customer may be undetermined for non-finalized vouchers
        "#{link_to v.customer.full_name, Rails.application.routes.url_helpers.customer_path(v.customer)} (#{v.seat})"
      else
        "[Purchase in progress: seatmap cannot be changed until purchase complete] (#{v.seat})"
      end
    end.join('<br/>')
  end

end


