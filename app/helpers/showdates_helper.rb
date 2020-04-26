module ShowdatesHelper

  def showdate_type_choices(show,new_showdate: nil)
    showdates = show.showdates
    options = []
    options.push(['In-theater',Showdate::IN_THEATER]) if new_showdate||showdates.any?(&:in_theater?)
    options.push(['Live stream',Showdate::LIVE_STREAM]) if new_showdate||showdates.any?(&:live_stream?)
    options.push(['Stream anytime',Showdate::STREAM_ANYTIME]) if new_showdate||showdates.any?(&:stream_anytime?)
    options_for_select(options)
  end

  def class_for_showdate_type(sd)
    if sd.live_stream? then Showdate::LIVE_STREAM
    elsif sd.stream_anytime? then Showdate::STREAM_ANYTIME
    else Showdate::IN_THEATER
    end
  end

  def showdate_seating_choices(showdate)
    if showdate.seatmap
      link_to 'Seats...', '', :class => 'btn btn-outline-primary btn-small'
    else
      content_tag 'span', 'General Admission'
    end
  end

  def time_in_words_relative_to(ed,sd)
    if (sd.month == ed.month) && (sd.day == ed.day) && (sd.year == ed.year)
      ed.strftime("%l:%M%p day of show")
    else
      ed.to_formatted_s(:showtime)
    end
  end

  def day_of_week_checkboxes(prefix)
    dow = %w[Mon Tue Wed Thu Fri Sat Sun]
    tag = ''
    dow.each_with_index do |day,i|
      idx = (i+1) % 7
      tag <<
        (content_tag('span', :class => 'hilite') do
          check_box_tag(prefix, idx, false,
            :name => "#{prefix}[]", :id => "#{prefix}_#{idx}") +
            content_tag('label', day, :for => "#{prefix}_#{idx}") 
        end)
    end
    tag.html_safe
  end


end
