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
    @shows = Show.find(:all, :order => 'opening_date')
    @season = params[:season] == "All" ? "All" : (params[:season] || Time.now.year).to_i
    @years = (@shows.first.opening_date.year .. @shows.last.closing_date.year)
    @shows.reject! { |s| !s.opening_date.within_season?(@season) } if @season.to_i > 0
    if @shows.empty?
      flash[:notice] = "There are no shows set up yet."
      redirect_to :action => new
    end
  end

  def new
    @show = Show.new
  end

  def create
    @show = Show.new(params[:show])
    if @show.save
      flash[:notice] = 'Show was successfully created.'
      redirect_to :action => 'list'
    else
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
