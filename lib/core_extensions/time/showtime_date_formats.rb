module CoreExtensions
  module Time
    module ShowtimeDateFormats
      def self.included(base)
        base::DATE_FORMATS.merge!({
            :compact => "%m/%d/%y",
            :filename => "%Y-%m-%d",
            :date_only => "%e %B %Y",
            :showtime => '%A, %b %-d, %-l:%M %p',
            :showtime_brief => '%a %-m/%-d, %-l:%M',
            :showtime_including_year => '%A, %b %-d, %Y, %-l:%M %p',
            :month_day_only => "%b %-d",
            :month_day_year => "%b %-d, %Y"})
      end
    end
  end
end
