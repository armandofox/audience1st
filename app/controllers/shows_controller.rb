class ShowsController < ApplicationController

  before_filter :is_boxoffice_manager_filter

  def index
    @superadmin = current_user.is_admin
    @season = (params[:season].to_i > 1900 ? params[:season].to_i : Time.this_season)
    year = Time.current.year
    @earliest = Show.minimum(:season) || year
    @latest = Show.maximum(:season) || year
    @season = @latest unless @season.between?(@earliest,@latest)
    @shows = Show.for_seasons(@season,@season)
    @page_title = "#{Option.humanize_season(@season)} Shows"
  end

  def new
    show_season = season_new_params.to_i
    listing_date = (show_season == Time.this_season ?
                      Date.today :  Time.at_beginning_of_season(show_season))
    @show = Show.new(:listing_date => listing_date,
                     :season => show_season,
                     :sold_out_dropdown_message => '(Sold Out)',
                     :sold_out_customer_info => 'No tickets on sale for this performance')
    @page_title = "Add new show"
  end

  def create
    @show = Show.new(show_params)
    if @show.save
      redirect_to edit_show_path(@show),
      :notice =>  'Show was successfully created. Click "Add Performances" below to start adding show dates.'
    else
      flash[:alert] = "There were errors creating the show: #{@show.errors.as_html}"
      render :action => 'new'
    end
  end

  def edit
    @show = Show.find(params[:id])
    @showdates = @show.showdates.includes(:valid_vouchers => :vouchertype).sort_by { |s| s.thedate }
    @is_boxoffice_manager = is_boxoffice_manager
    if params[:display].blank?
      @maybe_hide = "display: none;"
    end
    @page_title = %Q{Details: "#{@show.name}"}
  end

  def update
    @show = Show.find(params[:id])
    @showdates = @show.showdates
    if @show.update_attributes(show_params)
      redirect_to edit_show_path(@show), :notice => 'Show details successfully updated.'
    else
      flash[:alert] = ["Show details could not be updated: ", @show.errors.as_html]
      render :action => 'edit', :id => @show
    end
  end

  def destroy
    Show.find(params[:id]).destroy
    redirect_to shows_path
  end

  # migrating from protected attr to strong param
  # standard found here: https://www.fastruby.io/blog/rails/upgrades/strong-parameters-migration-guide.html
  private

  def season_new_params
    params.permit :season
    params.fetch :season, Time.this_season
  end

  def show_params
    permitted = params.require(:show).permit(:name, :event_type,
                                             :listing_date,
                                             :landing_page_url,
                                             :description,
                                             :patron_notes,
                                             :sold_out_dropdown_message,
                                             :sold_out_customer_info,
                                             :reminder_type)
    permitted
  end
end
