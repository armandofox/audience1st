class ShowsController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  before_filter :has_at_least_one, :except => [:new, :create]

  def index
    unless Show.find(:first)
      flash[:notice] = "There are no shows set up yet."
      redirect_to new_show_path
      return
    end
    @superadmin = current_user.is_admin
    @season = (params[:season].to_i > 1900 ? params[:season].to_i : Time.this_season)
    @earliest,@latest = Show.seasons_range
    @season = @latest unless @season.between?(@earliest,@latest)
    @shows = Show.all_for_season(@season)
  end

  def new
    @show = Show.new(:listing_date => Date.today,
      :sold_out_dropdown_message => '(Sold Out)',
      :sold_out_customer_info => 'No tickets on sale for this performance')
  end

  def create
    @show = Show.new(params[:show])
    if @show.save
      flash[:notice] = 'Show was successfully created. Click "Add A Performance" below to start adding show dates.'
      redirect_to edit_show_path(@show)
    else
      flash[:notice] = "There were errors creating the show."
      render :action => 'new'
    end
  end

  def edit
    @show = Show.find(params[:id])
    @showdates = @show.showdates.sort_by { |s| s.thedate }
    @is_boxoffice_manager = is_boxoffice_manager
    if params[:display].blank?
      @maybe_hide = "display: none;"
    end
  end

  def update
    @show = Show.find(params[:id])
    @showdates = @show.showdates
    if @show.update_attributes(params[:show])
      flash[:notice] = 'Show details successfully updated.'
      redirect_to edit_show_path(@show)
    else
      flash[:alert] = ["Show details were not updated: ", @show]
      render :action => 'edit', :id => @show
    end
  end

  def destroy
    Show.find(params[:id]).destroy
    redirect_to shows_path
  end
end
