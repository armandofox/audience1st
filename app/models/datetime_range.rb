class DatetimeRange

  attr_reader :start_date, :end_date, :time
  attr_reader :days_of_week

  def initialize(args={})
    @start_date = (args[:start_date] || Clock.now).to_date
    @end_date = (args[:end_date] || Clock.now).to_date
    @start_date,@end_date = @end_date,@start_date if @start_date > @end_date
    @time = (args[:time] || Time.now).to_time
    @days_of_week = args[:days_of_week] || []
    @dates = []
    raise(ArgumentError, "days_of_week must be an array of integers in range 0..6") unless
      @days_of_week.kind_of?(Enumerable) &&
      @days_of_week.all? { |d| d.kind_of?(Numeric) && d >= 0 && d <= 6 }
  end

  def dates
    return @dates unless @dates.empty?
    hour,min = @time.hour, @time.min
    (@start_date..@end_date).each do |day|
      @dates << day.to_time.change(:hour => hour, :min => min) if
        @days_of_week.include?(day.wday)
    end
    @dates
  end

  def count ; dates.size ; end
  

end

