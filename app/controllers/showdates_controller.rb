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
    @show = Show.find(params[:show_id])
    start_date,end_date = Time.range_from_params(params[:start], params[:end])
    days = params[:day]
    all_dates = DatetimeRange.new(:start_date => start_date, :end_date => end_date, :days => days,
      :time => Time.from_param(params[:time])).dates
    new_showdates = showdates_from_date_list(all_dates, params)
    redirect_to(:action => :new, :show_id => show) and return unless flash[:warning].blank?
    new_showdates.each do |showdate|
      unless showdate.save
        flash[:warning] = "Showdate #{showdate.thedate.to_formatted_s(:showtime)} could not be created: " <<
          showdate.errors.full_messages.join('<br/>')
        redirect_to(:action => :new, :show_id => @show) and return
      end
    end
    flash[:notice] = "#{new_showdates.size} showdates were successfully added."
    if params[:commit] =~ /back to list/i
      redirect_to :controller => :shows
    else
      redirect_to(:action => :new, :show_id => @show)
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
    @show = Show.find(params[:show_id])
    @advance_sales_cutoff = Option.nonzero_value_or_default(:advance_sales_cutoff, 0)
    @max_sales_default = @show.house_capacity
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

  private

  def showdates_from_date_list(dates, params)
    sales_cutoff = params[:advance_sales_cutoff].to_i
    max_sales = params[:max_sales].to_i
    description = params[:description].to_s

    dates.map do |date|
      s = @show.showdates.build(:thedate => date,
        :max_sales => max_sales,
        :end_advance_sales => date - sales_cutoff.minutes,
        :description => description)
      unless s.valid?
        flash[:warning] =
          "NO showdates were created, because the #{date.to_formatted_s(:showtime)} showdate had errors: " <<
          s.errors.full_messages.join('<br/>')
      end
      s
    end
  end
end
