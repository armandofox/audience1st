module CoreExtensions
  module Time
    module ToParam
      def self.included(base)
        base.extend(ClassMethods)
      end
      # Convert a Time or String into the weird params(1i),params(2i), format used by form helpers
      def to_form_param(prefix)
        { "#{prefix}(1i)" => year.to_s,
          "#{prefix}(2i)" => month.to_s,
          "#{prefix}(3i)" => day.to_s,
          "#{prefix}(4i)" => hour.to_s,
          "#{prefix}(5i)" => min.to_s
        }
      end
      module ClassMethods
        # Convert a hash with keys :year, :month, etc into a Time object
        def from_hash(hash)
          ::Time.zone.local(*['year','month','day','hour','minute'].map { |i| hash[i].to_i })
        end
        def from_param(param,default=::Time.current)
          return default if param.blank?
          return ::Time.zone.parse(param) unless param.kind_of?(Hash)
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
          return ::Time.current,::Time.current if json.blank?
          obj = JSON(json)
          min = ::Time.zone.parse(obj['start'].to_s).at_beginning_of_day
          max = ::Time.zone.parse(obj['end'].to_s).at_end_of_day
          min,max = max,min if min > max
          return min, max
        end
        # Convert 2 Time objects into a JSON date range for jquery-ui-datepicker
        def range_to_params(from,to)
          JSON[{'start' => from.strftime('%F'), 'end' => to.strftime('%F')}]
        end
      end
    end
  end
end
