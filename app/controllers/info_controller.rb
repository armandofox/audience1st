class InfoController < ApplicationController
  
  # RSS feed of ticket availability info: renders an XML view for external use
  def ticket_rss
    now = Time.now
    # end_date = now.next_year.at_beginning_of_year
    end_date = now + 3.months
    showdates =
      Showdate.find(:all,
                    :conditions => ["thedate BETWEEN ? AND ?", now, end_date],
                    :order => "thedate")
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
        desc << " - " << (sd.advance_sales? ? "Buy online now" :
                          "Advance sales ended, box office sales only")
      end
      @showdate_avail << [sd, desc, link]
    end
    @venue = Option.value(:venue)
    render :layout => false
  end

  # supports VXML voice playback of available shows
  def ticket_vxml
    @venue = Option.value(:venue)
    @xferphone = Option.value(:venue_telephone)
    # just check shows thru "this weekend"
    end_date = (Time.now + 1.day + 1.week).at_beginning_of_week
    showdates = Showdate.find(:all, :conditions =>
                              ["thedate BETWEEN ? and ?", Time.now, end_date],
                              :order => "thedate" )
    if (showdates.nil? || showdates.empty?)
      @next_perf = Showdate.find(:first, :order => 'thedate',
                                 :conditions => ["thedate >?",Time.now])
      render :template => "info/ticket_noperfs_vxml", :layout => false
    else
      @showdates_info = showdates.map do |s|
        [s.speak, s.availability_in_words, s.advance_sales? ]
      end
      render :layout => false
    end
  end

  # iCal-compatible feed of upcoming shows
  def calendar_ical
    this_year = Time.now.at_beginning_of_year
    @venue = Option.value(:venue)
    @showdates =
      Showdate.find(:all,
                    :conditions => ['thedate BETWEEN ? AND ?',
                                    this_year, this_year + 1.year],
                    :order => 'thedate')
    render :layout => false
  end
  
end
