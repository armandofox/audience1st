class SeatmapsController < ApplicationController

  before_action :is_boxoffice_manager_filter, :except => 'seatmap'

  def index
    @seatmaps = Seatmap.all.order(:name)
  end

  def show
    seatmap = Seatmap.find params[:id]
    send_data seatmap.csv, :type => 'text/csv', :filename => "#{seatmap.name}.csv"
  end

  def update
    seatmap = Seatmap.find params[:id]
    params.require(:seatmap).permit(:image_url, :name)
    if seatmap.update_attributes(params[:seatmap])
      flash[:notice] = 'Seatmap successfully updated.'
    else
      flash[:alert] = "Seatmap was not updated: #{seatmap.errors.as_html}"
    end
    redirect_to seatmaps_path
  end

  # AJAX responders for seatmap-related functions

  def seatmap
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance
    showdate = Showdate.find(params[:id]) 
    render :json => Seatmap.seatmap_and_unavailable_seats_as_json(showdate)
  end

end
