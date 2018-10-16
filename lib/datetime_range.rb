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
      candidate_date = day.to_time.in_time_zone.change(:hour => @hour, :min => @minute)
      @dates << candidate_date if @days.include?(candidate_date.wday)
    end
    @dates
  end

  def count ; dates.size ; end
  

end

