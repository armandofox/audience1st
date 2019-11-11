class InfoController < ActionController::Base

  # NOTE inheriting from AC::Base avoids inheriting stuff from APplicationController, such as maintenance mode
  # filter and force_ssl

  # Force all requests to 'look like' RSS
  # before_action do
  #   request.format = :rss
  # end
  # respond_to :rss
  # showdates in iCalendar/vCalendar format
  def showdates
    # these could be overridden by params[] later:
    from = Time.current
    to = Time.at_end_of_season(1 + Time.this_season)
    @showdates = Showdate.where('thedate BETWEEN ? AND ?', from, to).includes(:show)
    @host = request.host
  end
  
  # RSS feed of ticket availability info: renders an XML view for external use
  def ticket_rss
    now = Time.current
    # end_date = now.next_year.at_beginning_of_year
    end_date = now + 3.months
    showdates =
      Showdate.where("thedate BETWEEN ? AND ?", now, end_date).order('thedate')
    @showdate_avail = []
    showdates.each do |sd|
      case sd.availability_in_words
      when :sold_out
        desc = "SOLD OUT" ; link = false
      when :nearly_sold_out
        desc = "Nearly sold out" ; link = true
      else
        desc = "Available" ; link  = true
      end
      if link
        desc << " - " << (sd.advance_sales_open? ? "Buy online now" :
                          "Advance sales ended, box office sales only")
      end
      @showdate_avail << [sd, desc, link]
    end
    @venue = Option.venue
    render :layout => false
  end

  # richer availability info - using availability grades
  def availability
    lookahead = params[:q].to_i
    # pin to 1 year ahead
    lookahead = 90 if lookahead < 1 || lookahead > 366
    now = Time.current
    @showdates = Showdate.
      where('thedate BETWEEN ? AND ?', now, now + lookahead.days).order('thedate').
      select { |sd| !sd.price_range.empty? }
    render :layout => false
  end

end
