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
    warnings = []
    start_date,end_date = Time.range_from_params(params[:show_run_dates])
    all_dates = DatetimeRange.new(:start_date => start_date, :end_date => end_date, :days => params[:day],
      :hour => params[:time][:hour], :minute => params[:time][:minute]).dates

    existing_dates, new_dates = all_dates.partition { |date| Showdate.find_by(:thedate => date) }
    unless existing_dates.empty?
      warnings.push(t('showdates.already_exist', :dates => existing_dates.map { |d| d.to_formatted_s(:showtime) }.join(', ')))
    end
    new_showdates = Showdate.from_date_list(new_dates, params)
    Showdate.transaction do
      begin
        new_showdates.each { |showdate|  showdate.save! }
      rescue ActiveRecord::RecordInvalid => e
        sd = e.record
        return redirect_to(new_show_showdate_path(@show),
          :alert => I18n.translate('showdates.errors.invalid', :date => sd.thedate.to_formatted_s(:showtime), :errors => sd.errors.as_html))
      end
    end
    warnings.unshift(t('showdates.added', :count => new_showdates.size))

    redirect_to((params[:commit] =~ /back/i ? shows_path(:season => @show.season) : new_show_showdate_path(@show)),
      :notice => warnings.join('<br/>'.html_safe))

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
