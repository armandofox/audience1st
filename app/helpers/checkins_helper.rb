module CheckinsHelper

  # emit a guide letter in the leftmost column of a table when the first new item
  # starting with that letter is passed; otherwise emit nothing
  
  def letter_header_for(val)
    (val[0,1].upcase==@cur_ltr ? '' : @cur_ltr=val[0,1].upcase)
  end

  # return a list of this and next season's showdates and the corresponding
  # route URLs for checkin, suitable for options_for_select.

  def showdates_with_urls
    year = Time.now.year
    showdates = Showdate.all_showdates_for_seasons(year, year+1)
    choices = showdates.map do |sd|
      [sd.name_and_date_with_capacity_stats, walkup_sale_path(sd)]
    end
    options_for_select(choices, walkup_sale_path(@showdate))
  end

  #  comma-separated id's for a list of vouchers
  def ids(things)
    things.map(&:id).join(",")
  end

end
