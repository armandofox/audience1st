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
        _end = start.at_end_of_season

        start <= self && self <= _end
      end

      module ClassMethods
        # Needed since DB may not be in same timezone, so its notion of NOW() may
        # not be correct
        def this_season ; ::Time.current.this_season ; end
        def at_beginning_of_season(arg=nil) ; ::Time.current.at_beginning_of_season(arg) ; end
        def at_end_of_season(arg=nil) ; ::Time.current.at_end_of_season(arg) ; end
        def season_boundaries(year)
          year = year.year unless year.kind_of?(Numeric)
          start = ::Time.local(year,Option.season_start_month,
            Option.season_start_day).at_beginning_of_season
          _end = start.at_end_of_season
          [start, _end]
        end
      end
    end
  end
end
