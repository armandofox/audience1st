module ShowdatesHelper

  def percent_max_advance_sales_if_not_streaming(showdate)
    advance = showdate.percent_max_advance_sales
    p = " (#{number_to_percentage(advance, :precision => 0)} house)"
    if showdate.stream?
      ''
    elsif (advance >= 100)
      (content_tag 'span', p, :class => 'callout').html_safe
    else
      p
    end
  end

  def button_to_delete_performance(showdate)
    if showdate.total_sales.size.zero?
      form_tag show_showdate_path(showdate.show, showdate), :method => :delete, :class => 'form form-inline' do |f|
        submit_tag '&#x2716'.html_safe, :class => 'btn btn-sm d-inline a1-x-icon', :id => "delete_showdate_#{showdate.id}", 'data-confirm' => t('season_setup.confirm_delete_performance')
      end.html_safe
    end
  end

  def showdate_time_limit_for(thing, attr)
    showdate = if thing.kind_of?(Showdate) then thing else thing.showdate end
    if showdate.stream_anytime?
      thing.send(attr).to_formatted_s(:showtime)
    else
      time_in_words_relative_to(thing.send(attr), showdate.thedate)
    end
  end

  def options_for_before_or_after_curtain(time=0)
    before = 'minutes before performance starts'
    after = 'minutes after performance starts'
    selected = (time < 0 ? '-1' : '+1')
    options_for_select([[before, '+1'], [after, '-1']], selected)
  end

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
    seconds_between = (ed - sd).abs
    if seconds_between < 1.hour
      "#{(seconds_between / 60).to_i} minutes %s performance starts" % ( ed > sd ? 'after' : 'before' )
    elsif (sd.month == ed.month) && (sd.day == ed.day) && (sd.year == ed.year)
      ed.strftime("%l:%M%p day of show")
    elsif sd.year != ed.year
      ed.to_formatted_s(:showtime_including_year)
    else
      ed.to_formatted_s(:showtime)
    end
  end
end
