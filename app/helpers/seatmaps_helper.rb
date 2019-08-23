module SeatmapsHelper
  def seatmap_choices_for(show,editable)
    if editable
      select_tag('show[seatmap_id]', 
        (options_for_select([['None (general admission)', '']]) +
          options_from_collection_for_select(Seatmap.all, :id, :name, show.seatmap_id)),
        :class => 'form-control')
    else
      content_tag 'span', (show.seatmap.try(:name) || 'General admission'), :class => 'form-control'
    end
  end
end
