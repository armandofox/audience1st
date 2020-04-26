class Showdate < ActiveRecord::Base
  
  def show_name
    show.name
  end

  # Used for CSS classes, Option menu values, etc for type of showdate
  Showdate::IN_THEATER = 'Tt'
  Showdate::LIVE_STREAM = 'Tl'
  Showdate::STREAM_ANYTIME = 'Ts'

  def performance_type
    if live_stream? then "Live Stream"
    elsif stream_anytime? then "Stream Anytime"
    else "In-theater"
    end
  end

  def seating_type_and_capacity
    if stream?                  then performance_type
    elsif has_reserved_seating? then seatmap.name_with_capacity
    else                             "General Admission (#{house_capacity})"
    end
  end

  def printable_name
    show_name + " - " + printable_date_with_description
  end

  def printable_name_with_description
    description.blank? ? show_name : "#{show_name} (#{description})"
  end

  def printable_date_with_type
    label = thedate.to_formatted_s(:showtime_brief)
    label << " (#{performance_type})" if stream?
    label
  end
  def printable_date_brief
    thedate.to_formatted_s(:showtime_brief)
  end
  def printable_date
    thedate.to_formatted_s(:showtime)
  end

  def printable_date_with_description
    label = live_stream? ? 'Live Stream ' : stream_anytime? ? 'Stream Anytime Until ' : ''
    label << (description.blank? ? printable_date : "#{printable_date} (#{description})")
    label
  end

  def name_and_date_with_capacity_stats
    sprintf "#{printable_name} (%d)", advance_sales_vouchers.size
  end
  
  def menu_selection_name
    name = printable_date_with_description
    if sold_out?
      name = [name, show.sold_out_dropdown_message].join ' '
    elsif nearly_sold_out?
      name << " (Nearly Sold Out)"
    end
    name
  end

  
  # returns two elements indicating the lowest-priced and highest-priced
  # publicly-available tickets.
  def price_range
    public_prices = valid_vouchers.select(&:public?).map(&:price).reject(&:zero?)
    public_prices.empty? ? [] : [public_prices.min, public_prices.max]
  end

  def availability_grade
    sales = percent_sold.to_i
    if sold_out? then 0
    elsif sales >= Option.nearly_sold_out_threshold then 1
    elsif sales >= Option.limited_availability_threshold then 2
    else 3
    end
  end

  def availability_in_words
    pct = percent_sold
    sold_out? ? :sold_out :
      pct >= Option.nearly_sold_out_threshold ? :nearly_sold_out :
      :available
  end

end
