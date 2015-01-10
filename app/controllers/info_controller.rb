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
    @venue = Option.venue
    render :layout => false
  end

end
