module SeatmapsHelper
  def seatmap_choices_for(show)
    options_for_select([['None (general seating)', '']]) +
      options_from_collection_for_select(Seatmap.all, :id, :name, show.seatmap_id)
  end
end
