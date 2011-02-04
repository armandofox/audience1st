module BoxOfficeHelper

  # emit a guide letter in the leftmost column of a table when the first new item
  # starting with that letter is passed; otherwise emit nothing
  
  def letter_header_for(val)
    (val[0,1].upcase==@cur_ltr ? '' : @cur_ltr=val[0,1].upcase)
  end

end
