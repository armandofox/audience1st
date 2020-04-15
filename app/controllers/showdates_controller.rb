class ShowdatesController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  before_filter :load_show

  private

  def load_show
    @show = Show.find params[:show_id]
    redirect_to shows_path unless  @show.kind_of? Show
  end

  public
  
  def create
    start_date,end_date = Time.range_from_params(params[:show_run_dates])
    all_dates = DatetimeRange.new(:start_date => start_date, :end_date => end_date, :days => params[:day],
      :hour => params[:time][:hour], :minute => params[:time][:minute]).dates
    new_showdates = Showdate.from_date_list(all_dates, params)
    return redirect_to(new_show_showdate_path(@show)) unless flash[:alert].blank?
    new_showdates.each do |showdate|
      unless showdate.save
        flash[:alert] = "Showdate #{showdate.thedate.to_formatted_s(:showtime)} could not be created: #{showdate.errors.as_html}"
        redirect_to new_show_showdate_path(@show)
        return
      end
    end
    flash[:notice] = t('showdates.added', :count => new_showdates.size)
    if params[:commit] =~ /back to list/i
      redirect_to shows_path(:season => @show.season)
    else
      redirect_to new_show_showdate_path(@show)
    end
  end
    
  def destroy
    showdate = Showdate.find(params[:id])
    show = showdate.show
    showdate.destroy
    redirect_to edit_show_path(show), :notice => 'Show date successfully deleted.'
  end

  def new
    @advance_sales_cutoff = Option.advance_sales_cutoff
    @max_sales_default = 0
  end

  def edit
    @showdate = Showdate.find(params[:id])
    @default_date = @showdate.thedate
    @default_cutoff_date = @showdate.end_advance_sales
  end

  def update
    @showdate = Showdate.find(params[:id])
    if @showdate.update_attributes(params[:showdate])
      flash[:notice] = 'Changes saved.'
      redirect_to edit_show_path(@showdate.show)
    else
      flash[:alert] = @showdate.errors.as_html
      redirect_to edit_show_showdate_path(@showdate.show,@showdate)
    end
  end

end
