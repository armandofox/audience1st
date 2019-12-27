class Showdate < ActiveRecord::Base
  
  def show_name
    show.name
  end

  def printable_name
    show_name + " - " + printable_date_with_description
  end

  def printable_name_with_description
    description.blank? ? show_name : "#{show_name} (#{description})"
  end

  def printable_date
    thedate.to_formatted_s(:showtime)
  end

  def printable_date_with_description
    description.blank? ? printable_date : "#{printable_date} (#{description})"
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
