module SeatmapsHelper
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
