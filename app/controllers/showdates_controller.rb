class ShowdatesController < ApplicationController

  before_action :is_boxoffice_manager_filter
  before_action :load_show

  private

  def load_show
    @show = Show.find params[:show_id]
    redirect_to shows_path unless  @show.kind_of? Show
  end

  public
  
  def create
    warnings = []
    cutoff = params[:advance_sales_cutoff].to_i.minutes
    # determine date list from EITHER the date range, or for stream-anytime, single date
    if params[:showdate][:stream_anytime].blank?
      start_date,end_date = Time.range_from_params(params[:show_run_dates])
      all_dates = DatetimeRange.new(:start_date => start_date, :end_date => end_date, :days => params[:day],
      :hour => params[:time][:hour], :minute => params[:time][:minute]).dates
    else
      all_dates = [ Time.from_hash(params[:stream_until]) ]
    end

    existing_dates, new_dates = all_dates.partition { |date| Showdate.find_by(:thedate => date) }
    unless existing_dates.empty?
      warnings.push(t('showdates.already_exist', :dates => existing_dates.map { |d| d.to_formatted_s(:showtime) }.join(', ')))
    end
    new_showdates = Showdate.from_date_list(new_dates, cutoff, showdate_params)
    Showdate.transaction do
      begin
        new_showdates.each { |showdate|  showdate.save! }
      rescue StandardError => e
        sd = e.record
        return redirect_to(new_show_showdate_path(@show),
          :alert => I18n.translate('showdates.errors.invalid', :date => sd.thedate.to_formatted_s(:showtime), :errors => sd.errors.as_html))
      end
    end
    warnings.unshift(t('showdates.added', :count => new_showdates.size))
    if new_showdates.any? { |v| v.max_advance_sales.zero? }
      warnings.push(t('showdates.zero_max_sales', :advance => (new_showdates.any?(&:stream?) ? '' : 'advance ')))
    end
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
    @showdate = @show.showdates.build(:max_advance_sales => @max_sales_default, :thedate => Time.current)
  end

  def edit
    @showdate = Showdate.find(params[:id])
    @default_date = @showdate.thedate
  end

  def update
    @showdate = Showdate.find(params[:id])
    seatmap_changed = (@showdate.seatmap_id.to_i != params[:showdate][:seatmap_id].to_i)
    show = @showdate.show
    parms = showdate_params()
    if @showdate.update_attributes(parms)
      flash[:notice] = 'Changes saved.'
      redirect_to (seatmap_changed ?
                     edit_show_showdate_path(show,@showdate) :
                     edit_show_path(show))
    else
      flash[:alert] = @showdate.errors.as_html
      redirect_to edit_show_showdate_path(show,@showdate)
    end
  end

  private
  
  def showdate_params
    p = params.require(:showdate).permit :thedate, :house_capacity, :max_advance_sales,
                                     :description, :long_description, :show_id, :seatmap_id,
                                     :live_stream, :stream_anytime, :access_instructions,
                                     :open_house_seats, :occupied_house_seats, :house_seats
    # if house_seats is provided, convert to an array...
    if p.has_key?(:house_seats)
      p[:house_seats] = p[:house_seats].split(/\s*,\s*/).sort
    elsif (p.has_key?(:open_house_seats) || p.has_key?(:occupied_house_seats))
      p[:house_seats] = (p.delete(:open_house_seats) + "," + p.delete(:occupied_house_seats)).
                          split(/\s*,\s*/).sort
    end
    p
  end

end
