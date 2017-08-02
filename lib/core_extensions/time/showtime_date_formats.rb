module CoreExtensions
  module Time
    module ShowtimeDateFormats
      def self.included(base)
        base::DATE_FORMATS.merge!({
            :compact => "%m/%d/%y",
            :filename => "%Y-%m-%d",
            :date_only => "%e %B %Y",
            :showtime => '%A, %b %-e, %-l:%M %p',
            :showtime_including_year => '%A, %b %-e, %Y, %-l:%M %p',
            :month_day_only => "%b %-e",
            :month_day_year => "%b %-e, %Y"})
      end
    end
  end
end
