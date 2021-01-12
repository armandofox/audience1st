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
    def failure_message_when_negated
      "expected #{@target.inspect} not to include any element matching #{@regex.inspect}"
    end
  end
  def include_match_for(regex)
    IncludeMatchFor.new(regex)
  end

  # test if a voucher collection includes voucher(s) with certain attributes
  class HaveVoucherMatching
    def initialize(num,args)
      @num = num
      @attribs = args
    end
    def matches?(target)
      @target = target
      matches = target.select do |v|
        @attribs.keys.all? { |k| v.send(k) == @attribs[k] }
      end
      @matched = matches.size
      @matched == @num
    end
    def failure_message
      "expected to find #{@num} vouchers matching #{@attribs.inspect}, but found #{@matched}"
    end
    def failure_message_when_negated
      "expected not to find #{@num} vouchers matching #{@attribs.inspect}, but I did"      
    end
  end
  def have_voucher_matching(args)
    HaveVoucherMatching.new(1, args)
  end
  def have_vouchers_matching(num, args)
    HaveVoucherMatching.new(num, args)
  end
end
