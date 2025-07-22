class SeatmapsController < ApplicationController

  before_action :is_boxoffice_manager_filter, :except => %w(seatmap assign_seats)

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
    if @seatmap.update(seatmaps_update_params)
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
    # if this is an 'admin' level user, make sure "holdback" restrictions are ignored.
    showdate = Showdate.find(params[:id]) 
    restrict_to_zone = params[:zone]
    already_selected = params[:selected].to_s.split(/\s*,\s*/)
    if showdate.has_reserved_seating?
      render :json => Seatmap.seatmap_and_unavailable_seats_as_json(
               showdate,
               restrict_to_zone: restrict_to_zone,
               selected: already_selected,
               is_boxoffice: @gAdminDisplay)
    else
      render :json => {'map' => nil}
    end
  end

  def raw_seatmap
    render :json => Seatmap.raw_seatmap_as_json(Seatmap.find params[:id])
  end
  
  def house_seats_seatmap
    # seatmap for a particular show id showing House Seats as 'selected', reserved
    # seats as 'unavailable', and unreserved seats as 'available'
    render :json => Seatmap.house_seats_seatmap_as_json(Showdate.find params[:id])
  end

  def assign_seats
    # XHR call with params['seats'] = JSON array of selected seats, params['vouchers'] =
    #  comma-separated IDs of vouchers
    vouchers = Voucher.find(params[:vouchers].split(/\s*,\s*/))
    seats = params[:seats].split(/\s*,\s*/)
    error_message = nil
    # This is messy: we want a transaction so that if ANY seat assignment fails they ALL rollback,
    # but the ActiveRecord::Rollback exception breaks out of the transaction but cannot be
    # rescued.  (Normally we'd put the error message render into a rescue of the rollback exception)
    Voucher.transaction do
      vouchers.each_with_index do |v,i|
        unless v.assign_seat(seats[i])
          error_message = v.errors.full_messages.join(', ')
          raise ActiveRecord::Rollback # this exception doesn't need to be rescued
        end
      end
    end
    if error_message
      render(:status => :bad_request, :plain => error_message)
    else
      head :ok
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

