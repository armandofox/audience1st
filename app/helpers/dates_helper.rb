module DatesHelper

  def date_range(from,to, fmt=:compact)
    "#{from.to_formatted_s(fmt)}-#{to.to_formatted_s(fmt)}"
  end
  
  def select_date_with_shortcuts(name, options={})
    t = Time.current
    t8601 = t.iso8601
    start_date = (options[:from] || 1.day.ago).at_beginning_of_day
    end_date = (options[:to] || t).at_beginning_of_day
    start_date,end_date = end_date,start_date if start_date > end_date
    show_run = if @show.try(:opening_date) then %Q[
                        { text: 'This production',
                          dateStart: function() { return moment('#{@show.opening_date.iso8601}') },
                          dateEnd:   function() { return moment('#{@show.closing_date.iso8601}') }
                        }, ]
               else '' end
    init_range = %Q{
{ start: new Date('#{start_date.iso8601}'), end: new Date('#{end_date.iso8601}') }
}
      json = %Q{
{
  initialText: 'Select date range...',
  clearButtonText: '',
  cancelButtonText: '',
  applyButtonText: 'OK',
  datepickerOptions : {  numberOfMonths : 3, minDate : null, maxDate : null  },
  presetRanges: [
  #{show_run} {
    text:      'Today',
    dateStart: function() { return moment('#{t8601}') },
    dateEnd:   function() { return moment('#{t8601}') }
  }, {
    text:      'Past 7 days',
    dateStart: function() { return moment('#{(t-7.days).iso8601}') },
    dateEnd:   function() { return moment('#{t8601}') }
  }, {
    text:      'Month to date',
    dateStart: function() { return moment('#{t.at_beginning_of_month.iso8601}') },
    dateEnd:   function() { return moment('#{t8601}') }
  }, {
    text:      'Year to date',
    dateStart: function() { return moment('#{t.at_beginning_of_year.iso8601}') },
    dateEnd:   function() { return moment('#{t8601}') }
  }, {
    text:      'Last year',
    dateStart: function() { return moment('#{(t-1.year).at_beginning_of_year.iso8601}') },
    dateEnd:   function() { return moment('#{(t-1.year).at_end_of_year.iso8601}') }
  }, {
    text:      'Season to date',
    dateStart: function() { return moment('#{t.at_beginning_of_season.iso8601}') },
    dateEnd:   function() { return moment('#{t8601}') }
  }, {
    text:      'Last season',
    dateStart: function() { return moment('#{(t-1.year).at_beginning_of_season.iso8601}') },
    dateEnd:   function() { return moment('#{(t-1.year).at_end_of_season.iso8601}') }
  }, {
    text:      'All time',
    dateStart: function() { return moment('1968-01-01') },
    dateEnd:   function() { return moment('#{t8601}') }
  }]
}
}
    js = javascript_tag(%Q{
$('##{name}').daterangepicker(#{json});
$('##{name}').daterangepicker('setRange', #{init_range});
})
    if (en = options[:enables])
      js << javascript_tag(%Q{
$('##{name}').daterangepicker({ open: function() { $('#{en}').prop('checked',true); } })
})
    end
    text_field_tag(name,'',:class => options[:class]) << "\n" << popup_help_for(:select_dates) <<  "\n" << js

  end

end
