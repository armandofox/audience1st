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
    return redirect_to(seatmaps_path, :alert => "Seatmap was NOT uploaded because of errors: #{@seatmap.errors.as_html}") unless @seatmap.valid?
    # as a courtesy, check if URI is fetchable
    check_image
    @seatmap.save!
    redirect_to seatmaps_path
  end

  def update
    return destroy if params[:commit] =~ /delete/i
    @seatmap = Seatmap.find params[:id]
    if @seatmap.update_attributes(seatmaps_update_params)
      flash[:notice] = 'Seatmap successfully updated.'
    else
      flash[:alert] = "Seatmap was NOT updated because of errors: #{seatmap.errors.as_html}"
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
    # return the seatmap for this production, and array of UNAVAILABLE seats for this performance.
    # if 'selected' is passed, it is a comma-separated list of full seat labels to show as
    # already-selected seats (if the seatmap workflow in question respects it).
    showdate = Showdate.find(params[:id]) 
    restrict_to_zone = params[:zone]
    already_selected = params[:selected]
    if showdate.has_reserved_seating?
      render :json => Seatmap.seatmap_and_unavailable_seats_as_json(showdate, restrict_to_zone)
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
    permitted = params.permit(:csv, :name, :image_url)
    if permitted[:csv].blank?
      csv_contents = ''
    else
      # treat all files as UTF-8, which is safe since all legal ASCII files are also UTF-8.
      # If we fail to do this, files with (eg) UTF-8 BOM, or UTF-8 characters, will choke
      # since the tempfile created by upload is apparently ASCII-8bit by default.
      csv_contents = File.new(permitted[:csv].tempfile, 'r:bom|utf-8').read
    end
    { :csv => csv_contents,
      :name => permitted[:name],
      :image_url => permitted[:image_url] }
  end

  def seatmaps_update_params
    params.require(:seatmap).permit(:name, :image_url)
  end
end

