if VERSION <= "1.8.7"
  module Enumerable
    # this method is built in as of 1.8.7
    def product(other)
      self.map do |e1|
        other.map do |e2|
          e1, e2
        end
      end
    end
  end
end
