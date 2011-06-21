class DatetimeRange

  attr_accessor :start_date, :end_date, :time
  attr_accessor :days_of_week

  def initialize(args={})
    @start_date = (args[:start_date] || Clock.now).to_date
    @end_date = (args[:end_date] || Clock.now).to_date
    @start_date,@end_date = @end_date,@start_date if @start_date > @end_date
    @time = (args[:time] || Time.now).to_time
    @days_of_week = args[:days_of_week] || []
  end

  

end

