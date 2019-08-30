class SeatmapsController < ApplicationController

  # AJAX responders for seatmap-related functions

  def seatmap
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance
    showdate = Showdate.find(params[:id]) 
    render :json => Seatmap.seatmap_and_unavailable_seats_as_json(showdate)
  end

end
