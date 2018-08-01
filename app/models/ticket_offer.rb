
class TicketOffer

  attr_accessor :showdate,:price,:noffered,:nsold,:vouchertype

  class NoPerfMatch < RuntimeError ; end
  class NoVoucherMatch < RuntimeError ; end

  def initialize(showdate_as_date, _price, _noffered, _nsold,
                 name_str="%goldstar%")
    @price,@noffered,@nsold = _price,_noffered.to_i,_nsold.to_i
    raise(ArgumentError, "Number offered and sold must be >= 0") unless
      (@noffered >= 0 && @nsold >= 0)
    # from the price and showdate, determine if we have assigned a
    # vouchertype corresponding to this.
    showdate_as_date = Time.zone.parse(showdate_as_date) unless showdate_as_date.kind_of?(Time)
    showdates = Showdate.where('thedate = ?',showdate_as_date)
    if showdates.length != 1
      raise(NoPerfMatch,
             "Found #{showdates.length} performances matching " <<
             "#{showdate_as_date} (expected 1)" )
    end
    # find vouchertype
    @showdate = showdates.first
    vtypes = @showdate.vouchertypes.where("name LIKE ? AND price = ?", name_str, price)
    if vtypes.length != 1
      raise(NoVoucherMatch,
            "Found #{vtypes.length} voucher types matching '#{name_str}'" <<
            sprintf(" at price %.02f ", price) <<
             "for #{@showdate.printable_name}: " <<
            vtypes.map { |v| ("#{v.name} (id=#{v.id})" rescue "(nil)") }.join(", "))
    end
    @vouchertype = vtypes.first
  end

  def to_s
    s = sprintf("%s: %2d/%2d @ $ %.02f", showdate.printable_name,
                nsold, noffered, price)
    if vouchertype
      s << "(matches vouchertype ID #{vouchertype.id} '#{vouchertype.name}')"
    else
      s << "ERROR: does not match any valid vouchertype for this showdate"
    end
  end

  def self.total_offered(ary)
    ary.to_a.inject(0) { |s,o| s + o.noffered }
  end

  def self.total_sold(ary)
    ary.to_a.inject(0) { |s,o| s + o.nsold }
  end

  def self.unsold(ary)
    ary.to_a.inject(0) { |s,o| s + o.noffered - o.nsold }
  end
    
end

