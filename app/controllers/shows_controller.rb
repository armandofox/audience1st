class ShowsController < ApplicationController

  before_filter(:is_boxoffice_manager_filter,
                :add_to_flash => "Only Box Office Manager can modify show information",
                :redirect_to => {:controller =>'customers',:action =>'welcome'})
  before_filter :has_at_least_one, :except => [:new, :create]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @superadmin = Customer.find(logged_in_id).is_admin rescue false
    @season = (params[:season].to_i > 1900 ? params[:season].to_i : Time.this_season)
    @shows = Show.find(:all, :conditions => ['opening_date BETWEEN ? AND ?', Time.now.at_beginning_of_season(@season), Time.now.at_end_of_season(@season)])
    if @shows.empty?
      @shows = Show.find(:all, :order => 'opening_date')
      if @shows.empty?
        flash[:notice] = "There are no shows set up yet."
        redirect_to :action => 'new'
      end
    end
    @earliest = Show.find(:first, :order => 'opening_date').opening_date.year
    @latest = Show.find(:first, :order => 'opening_date DESC').opening_date.year
  end

  def new
    @show = Show.new(:listing_date => Date.today)
  end

  def create
    @show = Show.new(params[:show])
    if @show.save
      flash[:notice] = 'Show was successfully created. Click "Add A Performance" below to start adding show dates.'
      redirect_to :action => 'edit', :id => @show
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
    @showdates = @show.showdates.sort_by { |s| s.thedate }
    if @show.update_attributes(params[:show])
      flash[:notice] = 'Show details successfully updated.'
      redirect_to :action => 'edit', :id => @show
    else
      render :action => 'edit', :id => @show
    end
  end

  def destroy
    Show.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
