class SeatingZonesController < ApplicationController

  before_action :is_boxoffice_manager_filter

  def index
    @seating_zones = SeatingZone.all
    @sz ||= SeatingZone.new
  end

  def create
    @sz = SeatingZone.create(seating_zones_params)
    if @sz.errors.empty?
      redirect_to seating_zones_path, :notice => "Seating zone '#{@sz.short_name}' (#{@sz.name}) created successfully."
    else
      @seating_zones = SeatingZone.all # to reload index page
      flash.now[:alert] = @sz.errors.as_html
      render :action => 'index'
    end
  end

  def destroy
    @sz = SeatingZone.find params[:id]
    if @sz.seatmaps.empty?
      @sz.destroy
      redirect_to seating_zones_path, :notice => "Seating zone '#{@sz.short_name}' (#{@sz.name}) deleted."
    else
      redirect_to seating_zones_path, :alert => 'Seating zone cannot be deleted because it is used by one or more seating charts.'
    end
  end

  private

  def seating_zones_params
    params.require(:seating_zone).permit(:name, :short_name, :display_order)
  end
  
end
