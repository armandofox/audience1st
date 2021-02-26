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
    @seatmap = Seatmap.new(seatmaps_new_params)
    @seatmap.parse_csv
    return redirect_to(seatmaps_path, :alert => "Seatmap CSV has errors: #{@seatmap.errors.as_html}") unless @seatmap.valid?
    # as a courtesy, check if URI is fetchable
    check_image
    @seatmap.save!
    redirect_to seatmaps_path
  end

  def update
    return destroy if params[:commit] =~ /delete/i
    @seatmap = Seatmap.find params[:id]
    if @seatmap.update(seatmaps_update_params)
      flash[:notice] = 'Seatmap successfully updated.'
    else
      flash[:alert] = "Seatmap was not updated: #{seatmap.errors.as_html}"
    end
    check_image
    redirect_to seatmaps_path
  end

  def destroy
    @seatmap = Seatmap.find params[:id]
    return redirect_to(seatmaps_path, :alert => 'You cannot delete a seatmap if it is associated with any performances.') unless @seatmap.showdates.empty?
    if @seatmap.destroy
      flash[:notice] = "Seatmap '#{@seatmap.name}' deleted."
    else
      flash[:alert] = "Seatmap '#{@seatmap.name}' could not be deleted: #{@seatmap.errors.as_html}"
    end
    redirect_to seatmaps_path
  end

  # AJAX responders for seatmap-related functions

  def seatmap
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance
    showdate = Showdate.find(params[:id]) 
    if showdate.has_reserved_seating?
      render :json => Seatmap.seatmap_and_unavailable_seats_as_json(showdate)
    else
      render :json => {'map' => nil}
    end
  end

  # helpers

  def check_image
    unless @seatmap.image_url.blank?
      u = SimpleURIChecker.new(@seatmap.image_url)
      flash[:alert] = "Warning: #{u.errors.as_html}" unless u.check(:allowed_content_types => ['image/png', 'image/jpeg', 'image/svg'])
    end
  end

  private

  def seatmaps_new_params
    params.permit(:csv, :name, :image_url)
    { image_url: params[:image_url],
      name: params[:name],
      csv: params[:csv].read }
  end

  def seatmaps_update_params
    params.require(:seatmap).permit(:csv, :name, :image_url)
  end
end
