module CustomMatchers

  # test an enumerable to see if it includes a match for regex.
  class IncludeMatchFor
    include Enumerable
    def initialize(regex)
      @regex = regex
    end
    def matches?(target)
      target.any? { |elt|  elt.match(@regex) }
    end
    def failure_message
      "expected #{@target.inspect} to include at least 1 element matching #{@regex.inspect}"
    end
    def negative_failure_message
      "expected #{@target.inspect} not to include any element matching #{@regex.inspect}"
    end
  end
  def include_match_for(regex)
    IncludeMatchFor.new(regex)
  end
end
