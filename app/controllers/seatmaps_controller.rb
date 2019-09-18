class SeatmapsController < ApplicationController

  before_action :is_boxoffice_manager_filter, :except => 'seatmap'

  def index
    @seatmaps = Seatmap.all.order(:name)
  end

  def show
    seatmap = Seatmap.find params[:id]
    send_data seatmap.csv, :type => 'text/csv', :filename => "#{seatmap.name}.csv"
  end

  def create                    # must be reached by 'post' due to file upload
    params.permit(:csv, :name,:image_url)
    @seatmap = Seatmap.new(:image_url => params[:image_url], :name => params[:name])
    @seatmap.csv = params[:csv].read
    @seatmap.parse_csv
    return redirect_to(seatmaps_path, :alert => "Seatmap CSV has errors: #{@seatmap.errors.as_html}") unless @seatmap.valid?
    # as a courtesy, check if URI is fetchable
    check_image
    @seatmap.save!
    redirect_to seatmaps_path
  end

  def update
    @seatmap = Seatmap.find params[:id]
    params.require(:seatmap).permit(:image_url, :name)
    if @seatmap.update_attributes(params[:seatmap])
      flash[:notice] = 'Seatmap successfully updated.'
    else
      flash[:alert] = "Seatmap was not updated: #{seatmap.errors.as_html}"
    end
    check_image
    redirect_to seatmaps_path
  end

  # AJAX responders for seatmap-related functions

  def seatmap
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance
    showdate = Showdate.find(params[:id]) 
    render :json => Seatmap.seatmap_and_unavailable_seats_as_json(showdate)
  end

  # helpers

  def check_image
    unless @seatmap.image_url.blank?
      u = SimpleURIChecker.new(@seatmap.image_url)
      flash[:alert] = "Warning: #{u.errors.as_html}" unless u.check(:allowed_content_types => ['image/png', 'image/jpeg', 'image/svg'])
    end
  end

end
