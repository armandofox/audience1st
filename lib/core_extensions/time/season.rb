module CoreExtensions
  module Time
    module Season
      def self.included(base)
        base.extend(ClassMethods)
      end

      def at_end_of_day
        (self + 1.day).midnight - 1.second
      end

      def at_beginning_of_season(oldyear = nil)
        startmon = Option.season_start_month
        startday = Option.season_start_day
        if (oldyear)
          # year given: just return start of that season
          ::Time.local(oldyear.to_i, startmon, startday)
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

      def within_season?(year)
        year = year.year unless year.kind_of?(Numeric)
        start = ::Time.local(year,Option.season_start_month,
          Option.season_start_day).at_beginning_of_season
        (start <= self) && (self <= start.at_end_of_season)
      end

      module ClassMethods
        # Needed since DB may not be in same timezone, so its notion of NOW() may
        # not be correct
        def at_beginning_of_season(arg=nil) ; ::Time.now.at_beginning_of_season(arg) ; end
        def at_end_of_season(arg=nil) ; ::Time.now.at_end_of_season(arg) ; end
        def this_season ; ::Time.now.this_season ; end
        def db_now
          "\"#{::Time.now.to_formatted_s(:db)}\""
        end
        def from_param(param,default=::Time.now)
          return default if param.blank?
          return ::Time.parse(param) unless param.kind_of?(Hash)
          t = ::Time.local(0,1,1,0,0,0)
          [:year,:month,:day,:hour].each do |component|
            t = t.change(component => param[component].to_i) if param.has_key?(component)
          end
          t = t.change(:min => param[:minute].to_i) if param.has_key?(:minute)
          t = t.change(:sec => param[:second].to_i) if param.has_key?(:second)
          t
        end

        # Extract two dates from jquery-ui-datepicker formatted params field
        def range_from_params(json)
          return ::Time.now,::Time.now if json.empty?
          obj = JSON(json)
          min = ::Time.parse(obj['start'].to_s).at_beginning_of_day
          max = ::Time.parse(obj['end'].to_s).at_end_of_day
          min,max = max,min if min > max
          return min, max
        end
      end
    end
  end
end
