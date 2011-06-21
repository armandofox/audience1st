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
    sid = args[:show_id]
    unless Show.find_by_id(sid)
      flash[:warning] = "New showdate must be associated with an existing show" 
      render :action => 'new'
      return
    end
    @showdate = Showdate.new(args)
    if @showdate.save
      flash[:notice] = 'Show date was successfully created.'
      if params[:commit] =~ /add another/i
        redirect_to :action => 'new', :show_id => sid
      else
        redirect_to :controller => 'shows', :action => 'edit', :id => sid
      end
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
    if (most_recent = show.showdates.find(:first, :order => 'updated_at DESC'))
      opts = {
        :thedate => most_recent.thedate + 1.day,
        :end_advance_sales => most_recent.end_advance_sales + 1.day,
        :max_sales => most_recent.max_sales
      }
    else
      thedate = show.opening_date.to_time.change(:hour => 20)
      opts = {
        :thedate => thedate,
        :end_advance_sales => thedate - Option.nonzero_value_or_default(:advance_sales_cutoff, 0).minutes,
        :max_sales => 0
      }
    end
    @showdate = show.showdates.build(opts)
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

  def num_showdates
    new_dates = datetimes_from_range(params).size
    total_dates = new_dates + Show.find(params[:show_id]).showdates.count
    render :text => "#{new_dates} performances will be added, giving #{total_dates} total performances"
  end

end
