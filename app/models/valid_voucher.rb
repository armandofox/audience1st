# A ValidVoucher is a record that states "for a particular showdate ID, this particular type of voucher 
# is accepted", and encodes additional information such as the capacity limit for this vouchertype for thsi
#  performance, the start and end dates of redemption for this vouchertype, etc.

class ValidVoucher < ActiveRecord::Base
  # A valid_voucher must be associated with exactly 1 showdate and 1 vouchertype
  belongs_to :showdate
  belongs_to :vouchertype
  validates_associated :showdate
  validates_associated :vouchertype
  validates_numericality_of :max_sales_for_type

  # for a given showdate ID, a particular vouchertype ID should be listed only once.
  validates_uniqueness_of :vouchertype_id, :scope => :showdate_id, :message => "already valid for this performance"

  def visible_to(cust)
    Vouchertype.find(self.vouchertype_id).visible_to(cust)
  end

  def printable_name
    self.showdate.printable_name
  end

  def seats_remaining
    nseatsleft = self.showdate.total_seats_left
    if max_sales_for_type.zero?
      # no limits on this type, so limit is just how many seats are left
      return nseatsleft
    else
      # limits on type: sales limit is the lesser of the number of seats
      # left or the number of seats left of this type
    [nseatsleft, [0,max_sales_for_type-showdate.sales_by_type(vouchertype_id)].max].min
    end
  end
  
  # get number of seats available for a showdate, given a customer
  # (different customers have different purchasing rights), a list of
  # passwords (some voucher types are password protected), and whether
  # to ignore time-based sales cutoffs (default: false).
  # Returns an AvailableSeat object encapsulating the result of htis
  # computation along with an English explanation if appropriate.
  
  def self.numseats_for_showdate_by_vouchertype(sd,cust,vtype,opts={})
    av = AvailableSeat.new(sd,cust,vtype,0) # fail safe: 0 available
    ignore_cutoff = opts.has_key?(:ignore_cutoff) ? opts[:ignore_cutoff] : cust.is_boxoffice
    redeeming = opts.has_key?(:redeeming) ? opts[:redeeming] : false
    # Basic checks: is show sold out? have advance sales ended?
    sd = Showdate.find(sd) unless (sd.kind_of?(Showdate))
    if (res = sold_out_or_date_invalid(sd,ignore_cutoff))
      av.howmany = 0
      av.explanation = res
      av.staff_only = true
      return av
    end
    # Find the valid_vouchers, if any, that make this vouchertype eligible
    vtype = Vouchertype.find(vtype, :include => :valid_vouchers) unless
      vtype.kind_of?(Vouchertype)
    unless redeeming
      return av unless  check_visible_to(av,ignore_cutoff)
    end
    #vv = vtype.valid_vouchers.find_all_by_showdate_id(sd.id)
    vv  = vtype.valid_vouchers.select { |v| v.showdate_id == sd.id }
    if vv.empty?
      av.howmany = 0
      av.explanation = "Ticket type not valid for this performance"
      return av
    end
    if vv.length != 1
      raise "#{vv.length} entries for vouchertype #{vtype.id} and showdate #{sd.id} (should be 1)"
    end
    av.staff_only = false
    av.howmany,av.explanation = check_date_and_quantity(vv.first,ignore_cutoff)
    av
  end

  def self.numseats_for_showdate(sd,cust,opts={})
    sd = Showdate.find(sd) unless (sd.kind_of?(Showdate))
    sd.vouchertypes.map { |v| numseats_for_showdate_by_vouchertype(sd,cust,v,opts) }
     # BUG: retrieve passwords from opts
     # BUG: need to consider somewhere whether voucher is expired
  end

  private

  def self.check_visible_to(av, admin=false)
    cust = av.customer
    av.staff_only = true        # only staff can see reason for reject
    case av.vouchertype.offer_public
    when -1                     # external reseller
      av.explanation = "Sold by external reseller only"
      return false
    when 0                      # box office use only
      av.explanation = "Not for customer purchase"
      return (admin && av.vouchertype.price.to_f > 0.0) # don't show comps.
    when 1                      # subscribers only
      av.explanation = "Subscribers only"
      av.staff_only = false     # ok to show this to customer
      return cust.is_subscriber?
    when 2
      return true
    else
      raise "Unknown value #{av.vouchertype.offer_public} for offer_public"
    end
  end

  
  def self.sold_out_or_date_invalid(sd,ignore_cutoff)
    now = Time.now
    if sd.total_seats_left < 1
      "Performance is sold out"
    elsif  sd.thedate < now && !ignore_cutoff
      "Performance date has already passed"
    elsif sd.end_advance_sales < now && !ignore_cutoff
      "Advance reservations for this performance are closed"
    else
      nil
    end
  end

  def self.check_date_and_quantity(v,ignore_cutoff)
    if (howmany = v.seats_remaining).zero?
      [0, "None left"]
    elsif (!ignore_cutoff)
      # check date-related constraints
      if v.end_sales && v.end_sales < Time.now
        [0, "Advance sales for this ticket type have ended"]
      elsif v.start_sales && v.start_sales > Time.now
        [0, "Tickets go on sale #{v.start_sales.strftime('%b %e')}"]
      else
        [howmany, "available"]
      end
    else                      # ignore date constraints
      [howmany, "available"]
    end
  end
  
end
