# Given a starting and ending date, an array of days of the week as integers (0=Sunday),
# and an hour/minute expressed in the app's timezone, all passed in an options hash,
# construct a list of Time objects corresponding to
# showdates on those days of the week throughout the time range, in the app's timezone.
# Used for setting up showdates like "Every Tues, Thurs, Fri at 8pm from 6/1/18 to 8/15/18"

class DatetimeRange

  attr_reader :start_date, :end_date, :hour, :minute
  attr_reader :days

  def initialize(args={})
    @start_date = (args[:start_date] || Time.current).to_date
    @end_date = (args[:end_date] || Time.current).to_date
    @start_date,@end_date = @end_date,@start_date if @start_date > @end_date
    @hour = (args[:hour] || 0).to_i
    @minute = (args[:minute] || 0).to_i
    @days = (args[:days] || []).map(&:to_i)
    @dates = []
    raise(ArgumentError, "days must be an array of integers in range 0..6") unless
      @days.kind_of?(Enumerable) &&
      @days.all? { |d| d.kind_of?(Numeric) && d >= 0 && d <= 6 }
  end

  def dates
    return @dates unless @dates.empty?
    (@start_date..@end_date).each do |day|
      next unless @days.include?(day.wday)
      @dates << Time.zone.local(day.year, day.month, day.day, @hour, @minute)
    end
    @dates
  end

  def count ; dates.size ; end
  

end

