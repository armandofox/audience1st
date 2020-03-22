module SeatmapsHelper
  def display_seats_field(extra_classes: '', seats: '')
    text_field_tag 'seats', seats, :readonly => 'readonly', :id => nil, :class => "seat-display a1-passive-text-input #{extra_classes}"
  end
  def seats_from_params(p)
    (if p.respond_to?(:[]) then p[:seats] else p end).to_s.split( /\s*,\s*/ )
  end
  def display_seats(seats)
    seats.map(&:strip).join(',')
  end
  def ga_option ; options_for_select([['None (general admission)', '']]) ; end
  def seatmap_options(selected = nil)
    options_from_collection_for_select(Seatmap.all, :id, :name_with_capacity, selected)
  end
  def seatmap_choices_for(showdate)
    ga = !showdate.has_reserved_seating?
    sold = (showdate.total_sales.size > 0)
    choices =
      if    !sold then ga_option + seatmap_options(showdate.seatmap_id)
      elsif ga    then ga_option
      else  seatmap_options(showdate.seatmap_id)
      end
  end
end

