class ShowdatesController < ApplicationController

  before_filter :is_boxoffice_filter
  before_filter :is_boxoffice_manager_filter, :only => ['new', 'create', 'destroy', 'edit', 'update']


  def index
    redirect_to :controller => 'shows', :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => %w[create update destroy], :redirect_to => { :action => :list }

  def list
    if defined? params[:show_id]
      redirect_to :controller => 'shows', :action => 'edit', :id => params[:show_id]
    else
      redirect_to :controller => 'shows', :action => 'list'
    end
  end

  def create
    args = params[:showdate]
    raise "New showdate must be associated with an existing show" unless Show.find(args[:show_id])
    @showdate = Showdate.new(args)
    if @showdate.save
      flash[:notice] = 'Show date was successfully created.'
      redirect_to :controller => 'shows', :action => 'edit', :id => args[:show_id]
    else
      render :action => 'new'
    end
  end

  def destroy
    showdate = Showdate.find(params[:id])
    show_id = showdate.show_id
    showdate.destroy
    flash[:notice] = 'Show date successfully deleted.'
    redirect_to :controller => 'shows', :action => 'edit', :id => show_id
  end

  def new
    show = Show.find(params[:show_id])
    if show.showdates.to_a.length > 0
      latest_showdate = show.showdates.map {|x| x.thedate}.max
    else
      latest_showdate = Time.parse(show.closing_date.to_s) 
    end
    @showdate = Showdate.new
    @showdate.show_id = params[:show_id]
    @showdate.thedate = latest_showdate + 1.day
    @showdate.end_advance_sales = latest_showdate + 21.hours
  end

  def edit
    @showdate = Showdate.find(params[:id])
    @default_date = @showdate.thedate
    @default_cutoff_date = @showdate.end_advance_sales
  end

  def update
    @showdate = Showdate.find(params[:id])
    if @showdate.update_attributes(params[:showdate])
      flash[:notice] = 'Showdate ID ' + params[:id].to_s + ' was successfully updated.'
    end
    redirect_to :controller => 'shows', :action => 'edit', :id => @showdate.show.id
  end
end
