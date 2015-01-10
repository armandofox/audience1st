# new contructor for making a Time from menus

# add a couple of useful formats to ActiveSupport to_formatted_s conversion
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!({
  :compact => "%m/%d/%y",
  :filename => "%Y-%m-%d",
  :date_only => "%e %B %Y",
  :showtime => '%A, %b %-e, %-l:%M %p',
  :showtime_including_year => '%A, %b %-e, %Y, %-l:%M %p',
  :month_day_only => "%b %-e",
  :month_day_year => "%b %-e, %Y"
})

class Time
  # Needed since DB may not be in same timezone, so its notion of NOW() may
  # not be correct
  def self.db_now
    "\"#{Time.now.to_formatted_s(:db)}\""
  end

  def at_end_of_day
    (self + 1.day).midnight - 1.second
  end

  def at_beginning_of_season(oldyear = nil)
    startmon = Option.season_start_month
    startday = Option.season_start_day
    if (oldyear)
      # year given: just return start of that season
      Time.local(oldyear.to_i, startmon, startday)
    else
      startmon = 1 unless (1..12).include?(startmon)
      startday = 1 unless (1..31).include?(startday)
      newyr = (self.month > startmon || (self.month==startmon && self.mday >= startday)) ? self.year : (self.year - 1)
      self.change(:month => startmon, :day => startday, :hour => 0, :year => newyr)
    end
  end

  def at_end_of_season(oldyear = nil)
    if (oldyear)
      # just return end of that season
      self.at_beginning_of_season(oldyear) + 1.year - 1.second
    else
      self.at_beginning_of_season + 1.year - 1.second
    end
  end

  def this_season ; self.at_beginning_of_season.year ;  end

  def self.at_beginning_of_season(arg=nil) ; Time.now.at_beginning_of_season(arg) ; end
  def self.at_end_of_season(arg=nil) ; Time.now.at_end_of_season(arg) ; end
  def self.this_season ; Time.now.this_season ; end

  def within_season?(year)
    year = year.year unless year.kind_of?(Numeric)
    start = Time.local(year,Option.season_start_month,
                       Option.season_start_day).at_beginning_of_season
    (start <= self) && (self <= start.at_end_of_season)
  end

  def self.from_param(param,default=Time.now)
    return default if param.blank?
    return Time.parse(param) unless param.kind_of?(Hash)
    t = Time.local(0,1,1,0,0,0)
    [:year,:month,:day,:hour].each do |component|
      t = t.change(component => param[component].to_i) if param.has_key?(component)
    end
    t = t.change(:min => param[:minute].to_i) if param.has_key?(:minute)
    t = t.change(:sec => param[:second].to_i) if param.has_key?(:second)
    t
  end

  def self.range_from_params(minp,maxp)
    min = Time.from_param(minp)
    max = Time.from_param(maxp)
    min,max = max,min if min > max
    unless minp.kind_of?(Hash) && minp.has_key?(:hour)
      min = min.at_beginning_of_day
    end
    unless maxp.kind_of?(Hash) && maxp.has_key?(:hour)
      max = max.at_end_of_day
    end
    return min, max
  end

end

class Date
  def at_beginning_of_season(arg=nil)
    self.to_time.at_beginning_of_season(arg).to_date
  end
  def at_end_of_season(arg=nil)
    self.to_time.at_end_of_season(arg).to_date
  end
  def within_season?(arg)
    self.to_time.within_season?(arg)
  end
end
