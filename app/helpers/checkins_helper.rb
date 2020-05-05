module CheckinsHelper

  # if an availability number is zero, red background w/white text, else green w/white
  def class_for(num)
    num.to_i <= 0 ? 'text-white bg-danger' : 'text-white bg-success'
  end

  # emit a guide letter in the leftmost column of a table when the first new item
  # starting with that letter is passed; otherwise emit nothing
  
  def letter_header_for(val)
    (val[0,1].upcase==@cur_ltr ? '' : @cur_ltr=val[0,1].upcase)
  end

  # for a reserved-seating checkin list, show the seat number(s) alongside voucher type
  def ticket_type_with_seats(vouchers)
    if vouchers.all? { |v| v.seat.blank? }
      content_tag('span', vouchers.first.name, :class => 'vouchertype')
    else
      content_tag('span', "#{Voucher.seats_for(vouchers)}", :class => 'seats') +
        content_tag('span', " - #{vouchers.first.name}", :class => 'vouchertype')
    end
  end


  # return a list of this and next season's showdates and the corresponding
  # route URLs for checkin, suitable for options_for_select.

  def showdates_with_urls(current_showdate)
    current = current_showdate.thedate
    showdates = Showdate.
      in_theater.
      includes(:show).
      includes({:vouchers => [:vouchertype,:customer]}).
      where(:thedate => (current - 6.months .. current + 2.months)).order(:thedate)
    choices = showdates.map do |sd|
      [sd.name_and_date_with_capacity_stats, walkup_sale_path(sd)]
    end
    options_for_select(choices, walkup_sale_path(current_showdate))
  end

  #  comma-separated id's for a list of vouchers
  def ids(things)
    things.map(&:id).join(",")
  end

end
