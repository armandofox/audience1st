module SeatmapsHelper
  def seatmap_choices_for(showdate,editable)
    if editable
      select_tag('showdate[seatmap_id]', 
        (options_for_select([['None (general admission)', '']]) +
          options_from_collection_for_select(Seatmap.all, :id, :name, showdate.seatmap_id)),
        :class => 'form-control')
    else
      content_tag 'span', (showdate.seatmap.try(:name) || 'General admission'), :class => 'form-control'
    end
  end
end
