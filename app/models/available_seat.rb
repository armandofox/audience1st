# this class captures the idea of a seat being available for a customer
# and a showdate.  Availability is complicated and is computed by the
# class methods numseats_for_showdate and
# numseats_for_showdate_by_vouchertype in ValidVoucher.  This class
# captures the result of that computation.

class AvailableSeat

  attr_accessor :customer, :showdate, :vouchertype, :howmany,
  :explanation, :staff_only

  def <=>(other)
    self.showdate <=> other.showdate
  end
  
  def initialize(showdate,customer,vouchertype,howmany=0,explanation='',staff_only=nil)
    @customer = customer.kind_of?(Customer) ? customer: Customer.find(customer)
    raise "Invalid customer" unless @customer.kind_of?(Customer)
    @showdate = showdate.kind_of?(Showdate) ? showdate: Showdate.find(showdate)
    raise "Invalid showdate" unless @showdate.kind_of?(Showdate)
    @vouchertype = vouchertype.kind_of?(Vouchertype) ? vouchertype: Vouchertype.find(vouchertype)
    raise "Invalid vouchertype" unless @vouchertype.kind_of?(Vouchertype)
    @howmany = howmany.to_i
    @explanation = explanation.to_s
    @staff_only = staff_only
  end

  def to_s
    str = ""
    str << "#{self.howmany} of #{self.vouchertype.id} '#{self.vouchertype.name}'"
    str << "  <#{self.explanation}>"
    if self.staff_only
      str << " (STAFF ONLY)"
    end
    str << "\n"
  end

  def self.no_seats(voucher,showdate,explanation='')
    AvailableSeat.new(showdate,voucher.customer,voucher.vouchertype,0,explanation)
  end
  
  def available? ;  @howmany > 0;  end

  def name;  @vouchertype.name_with_price;  end
  
  def name_with_explanation
    @howmany > 0 ?  name : "#{name} (#{@explanation})"
  end

  def name_with_howmany_left(thresh = 10)
    name + (howmany < 1 ? " (not available)" :
            howmany < thresh ? " (#{howmany} left)" : "")
  end

  def showdate_name; @showdate.printable_name; end

  def showdate_name_with_explanation
    @howmany > 0 ? showdate_name : "#{showdate_name} (#{@explanation})"
  end

  def date_with_explanation
    @howmany > 0 ? showdate.menu_selection_name : "#{showdate.menu_selection_name} (#{@explanation})"
  end

  def vouchertype_id;  @vouchertype.id;  end

  def promo_codes
    codes = @vouchertype.valid_vouchers.map do
      |v| v.promo_code ? v.promo_code.split(',') : nil
    end.flatten.compact
    codes.empty? ? nil : codes.map {|s| s.upcase }
  end
      
  
  def showdate_id; @showdate.id; end
end
