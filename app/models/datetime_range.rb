class DatetimeRange

  attr_reader :start_date, :end_date, :time
  attr_reader :days

  def initialize(args={})
    @start_date = (args[:start_date] || Clock.now).to_date
    @end_date = (args[:end_date] || Clock.now).to_date
    @start_date,@end_date = @end_date,@start_date if @start_date > @end_date
    @time = (args[:time] || Time.now).to_time
    @days = (args[:days] || []).map(&:to_i)
    @dates = []
    raise(ArgumentError, "days must be an array of integers in range 0..6") unless
      @days.kind_of?(Enumerable) &&
      @days.all? { |d| d.kind_of?(Numeric) && d >= 0 && d <= 6 }
  end

  def dates
    return @dates unless @dates.empty?
    hour,min = @time.hour, @time.min
    (@start_date..@end_date).each do |day|
      @dates << day.to_time.change(:hour => hour, :min => min) if
        @days.include?(day.wday)
    end
    @dates
  end

  def count ; dates.size ; end
  

end

