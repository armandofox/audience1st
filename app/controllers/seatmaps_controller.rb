class SeatmapsController < ApplicationController

  # AJAX responders for seatmap-related functions

  def seatmap
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance
    showdate = Showdate.find(params[:id]) 
    seatmap = showdate.seatmap.json
    unavailable = showdate.occupied_seats.to_json
    render :json => %Q{ {"map": #{seatmap}, "unavailable": #{unavailable}} }
  end

end
