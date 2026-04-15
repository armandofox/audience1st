module DatesHelper

  def date_range(from,to, fmt=:compact)
    "#{from.to_formatted_s(fmt)}-#{to.to_formatted_s(fmt)}"
  end
  
  def select_date_with_shortcuts(elt_id, options={})
    # set up for DateRangePicker
    t = Time.current
    now = t.iso8601
    start_date = (options[:from] || 1.day.ago).at_beginning_of_day
    end_date = (options[:to] || t).at_beginning_of_day
    start_date,end_date = end_date,start_date if start_date > end_date

    ranges = {
      'Today': [now, now],
      'Past 7 days': [1.week.ago.iso8601, now],
      'Month to date': [1.month.ago.iso8601, now],
      'Year to date':  [t.at_beginning_of_year.iso8601, now],
      'Last year': [(t-1.year).at_beginning_of_year.iso8601, t.at_beginning_of_year.iso8601],
      'Season to date': [t.at_beginning_of_season.iso8601, now],
      'Last season': [(t-1.year).at_beginning_of_season.iso8601, (t-1.year).at_end_of_season.iso8601],
      'All time': [Time.parse('2007-01-01').iso8601, now]
    }
    if @show.try(:opening_date)
      ranges['This production'] = [@show.opening_date.iso8601, @show.closing_date.iso8601]
    end

    options = {
      ranges: ranges,
      startDate: start_date.iso8601,
      endDate:   end_date.iso8601,
      showDropdowns: true,
      minYear: 2007,
      maxYear: t.year + 5,
      autoApply: true,
      linkedCalendars: true,
      showCustomRangeLabel: true
    }

    classes =
      options[:class].blank? ? 'daterangepicker' : "daterangepicker #{options[:class]}" 

    input_tag = tag(:input, :type => 'text', :name => elt_id, :id => elt_id, :class => classes, :data => {:config => options})

    div1 = content_tag('div', input_tag, :class => 'd-inline')
    div2 = content_tag('div', popup_help_for(:select_dates), :class => 'd-inline')
    safe_join([div1, div2])
  end

end
