module CustomMatchers

  # test if 2 customers would be marked as near-dups based on first/last/street
  RSpec::Matchers.define :be_near_dups do
    match do |actual|
      a,b= actual.split(/::/)
      a = a.split(/,/)
      b = b.split(/,/)
      c1 = create(:customer, :first_name => a[0], :last_name => a[1], :street => a[2], :created_by_admin => true)
      c2 = create(:customer, :first_name => b[0], :last_name => b[1], :street => b[2], :created_by_admin => true)
      3.times { create(:customer, :first_name => Faker::Name.first_name + "1" , :last_name => Faker::Name.last_name, :street => Faker::Address.street_address) }
      res = Customer.find_suspected_duplicates
      res.size == 2 && res.include?(c1) && res.include?(c2)
    end
  end
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
