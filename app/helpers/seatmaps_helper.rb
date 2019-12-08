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
  def seatmap_options(selected = nil)
    options_for_select([['None (general admission)', '']]) +
      options_from_collection_for_select(Seatmap.all, :id, :name, selected)
  end
  def seatmap_choices_for(showdate,editable)
    if editable
      select_tag('showdate[seatmap_id]', seatmap_options(showdate.seatmap_id), :class => 'form-control')
    else
      content_tag 'span', (showdate.seatmap.try(:name) || 'General admission'), :class => 'form-control'
    end
  end
end
