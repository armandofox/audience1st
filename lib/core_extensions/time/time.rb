module CoreExtensions
  module Time
    # add a couple of useful formats to ActiveSupport to_formatted_s conversion
    ::Time::DATE_FORMATS.merge!({
        :compact => "%m/%d/%y",
        :filename => "%Y-%m-%d",
        :date_only => "%e %B %Y",
        :showtime => '%A, %b %-e, %-l:%M %p',
        :showtime_including_year => '%A, %b %-e, %Y, %-l:%M %p',
        :month_day_only => "%b %-e",
        :month_day_year => "%b %-e, %Y"})
  end
end
