module CheckinsHelper

  # emit a guide letter in the leftmost column of a table when the first new item
  # starting with that letter is passed; otherwise emit nothing
  
  def letter_header_for(val)
    (val[0,1].upcase==@cur_ltr ? '' : @cur_ltr=val[0,1].upcase)
  end

  # return a list of this and next season's showdates and the corresponding
  # route URLs for checkin, suitable for options_for_select.

  def showdates_with_urls(selected)
    current = @showdate.thedate
    showdates = Showdate.where(:thedate => (current - 2.months .. current + 2.months)).order(:thedate)
    choices = showdates.map do |sd|
      [sd.name_and_date_with_capacity_stats, walkup_sale_path(sd)]
    end
    options_for_select(choices, selected)
  end

  #  comma-separated id's for a list of vouchers
  def ids(things)
    things.map(&:id).join(",")
  end

end
