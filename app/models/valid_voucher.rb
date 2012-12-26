=begin rdoc
A ValidVoucher is a record indicating the conditions under which a particular
voucher type can be redeemed.  For non-subscriptions, the valid voucher refers
to a particular showdate ID.  For subscriptions, the showdate ID is zero.
#
is a record that states "for a particular showdate ID, this particular type of voucher
is accepted", and encodes additional information such as the capacity limit for this vouchertype for thsi
 performance, the start and end dates of redemption for this vouchertype, etc.
=end

class ValidVoucher < ActiveRecord::Base
  # A valid_voucher must be associated with exactly 1 showdate and 1 vouchertype
  belongs_to :showdate
  belongs_to :vouchertype
  validates_associated :showdate, :if => lambda { |v| !(v.vouchertype.bundle?) }
  validates_associated :vouchertype
  validates_numericality_of :max_sales_for_type
  validates_presence_of :start_sales
  validates_presence_of :end_sales

  validate :check_dates

  require 'set'

  # for a given showdate ID, a particular vouchertype ID should be listed only once.
  validates_uniqueness_of :vouchertype_id, :scope => :showdate_id, :message => "already valid for this performance"

  attr_accessor :explanation    # tells customer/staff why the # of avail seats is what it is
  attr_accessor :invisible_explanation      # hides explanation completely from customer (eg, if promocode needed)
  

  # explanation when no seats are available
  cattr_accessor :no_seats_explanation

  private

  # Vouchertype's valid date must not be later than valid_voucher start date
  # Vouchertype expiration date must not be earlier than valid_voucher end date
  def check_dates
    errors.add_to_base("Dates and times for start and end sales must be provided") and return if (start_sales.blank? || end_sales.blank?)
    errors.add_to_base("Start sales time cannot be later than end sales time") and return if start_sales > end_sales
    vt = self.vouchertype
    if self.end_sales > (end_of_season = Time.now.at_end_of_season(vt.season))
      errors.add_to_base "Voucher type '#{vt.name}' is valid for the
        season ending #{end_of_season.to_formatted_s(:month_day_year)},
        but you've indicated sales should continue later than that
        (until #{end_sales.to_formatted_s(:month_day_year)})."
    end
  end
  
  public

  def to_s
    sprintf "%s max %3d %s- %s %s", vouchertype, max_sales_for_type,
    start_sales.strftime('%c'), end_sales.strftime('%c'),
    promo_code
  end
  
  delegate :name, :price, :visible_to, :season, :to => :vouchertype
  delegate :printable_name, :to => :showdate
  
  # returns a copy of this ValidVoucher, but with max_sales_for_type adjusted to
  # the number of tickets of THIS vouchertype for THIS show available to THIS customer.
  def adjust_for_customer(customer,supplied_promo_code = '')
    result = self.clone
    now = Time.now
    reason = invisible = ''
    inventory = self.seats_remaining
    self.max_sales_for_type = 0 # will be overwritten by correct answer
    # conditions that result in *zero* seats available to this customer:
    # without promo code, customer can't even see the offer
    if !promo_code_matches(supplied_promo_code)
      invisible = 'Promo code required'
    elsif !visible_to(customer)
      invisible = "Ticket sales of this type restricted to #{vouchertype.offer_public_as_string}"
    elsif showdate.thedate < now
      invisible = 'Event date is in the past'
    elsif showdate.saleable_seats_left < 1
      reason = 'Performance is sold out'
    elsif showdate.end_advance_sales < now
      result.explanation = 'Advance sales for this event are closed'
    elsif now < start_sales
      reason = "Tickets of this type not on sale until #{start_sales.to_formatted_s(:showtime)}"
    elsif now > end_sales
      reason = "Tickets of this type not sold after #{end_sales.to_formatted_s(:showtime)}"
    elsif inventory.zero?
      reason = "All tickets of this type have been sold"
    else
      self.max_sales_for_type = inventory
    end      
    result.explanation, result.invisible_explanation = reason,invisible
    result.freeze
  end

  def self.for_advance_sales(promo_codes = [])
    general_conds = "? BETWEEN start_sales AND end_sales"
    general_opts = [Time.now]
    promo_code_conds = "promo_code IS NULL OR promo_code = ''"
    promo_code_opts = []
    unless promo_codes.empty?
      promo_code_conds += " OR promo_code LIKE ? " * promo_codes.length
    end
    v = ValidVoucher.find(:all,
                          :conditions => ["#{general_conds} AND (#{promo_code_conds})", general_opts + promo_codes])
    v.to_set.classify( &:showdate_id )
  end

  # def seats_remaining
  #   nseatsleft = self.showdate.saleable_seats_left
  #   if max_sales_for_type.zero?
  #     # no limits on this type, so limit is just how many seats are left
  #     return nseatsleft
  #   else
  #     # limits on type: sales limit is the lesser of the number of seats
  #     # left or the number of seats left of this type
  #   [nseatsleft, [0,max_sales_for_type-showdate.sales_by_type(vouchertype_id)].max].min
  #   end
  # end

  def seats_remaining
    saleable_seats_left = showdate.saleable_seats_left
    if (max_sales_for_type.zero? || saleable_seats_left.zero?)
      # num seats left is just however many are left for show
      saleable_seats_left
    else
      # num seats may be inventory constrained. Result is the LEAST
      # of available seats left, or available seats for THIS TYPE.
      inventory_left_for_type = [(max_sales_for_type - showdate.sales_by_type(self.vouchertype_id)), 0].max
      [inventory_left_for_type, saleable_seats_left].min
    end
  end

  # get number of seats available for a showdate, given a customer
  # (different customers have different purchasing rights), a list of
  # promo_codes (some voucher types are promo_code protected), and whether
  # to ignore time-based sales cutoffs (default: false).
  # Returns an AvailableSeat object encapsulating the result of htis
  # computation along with an English explanation if appropriate.

  def self.numseats_for_showdate_by_vouchertype(sd,cust,vtype,opts={})
    av = AvailableSeat.new(self,cust,0) # fail safe: 0 available
    ignore_cutoff = opts.has_key?(:ignore_cutoff) ? opts[:ignore_cutoff] : cust.is_boxoffice
    redeeming = opts.has_key?(:redeeming) ? opts[:redeeming] : false
    # Basic checks: is show sold out? have advance sales ended?
    if (res = sold_out_or_date_invalid(sd,ignore_cutoff))
      av.howmany = 0
      av.explanation = res
      av.staff_only = false
      return av
    end
    # Find the valid_vouchers, if any, that make this vouchertype eligible
    unless redeeming
      return av unless  check_visible_to(av,ignore_cutoff)
    end
    vv  = vtype.valid_vouchers.select do |v|
      v.showdate_id == sd.id &&
        (redeeming || v.promo_code_matches(opts[:promo_code]))
    end
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
    sd.available_vouchertypes.map { |v| numseats_for_showdate_by_vouchertype(sd,cust,v,opts) }
     # BUG: retrieve promo_codes from opts
     # BUG: need to consider somewhere whether voucher is expired
  end

  # instantiate(logged_in_customer, purchasemethod, howmany=1)
  #  n vouchers of given vouchertype and for given showdate are created
  #  voucher is bound to customer
  # returns the list of newly-instantiated vouchers
  def instantiate(logged_in_customer, purchasemethod, howmany=1, comment='')
    Array.new(howmany) do |i|
      Voucher.new_from_vouchertype(
        self.vouchertype,
        :purchasemethod => purchasemethod,
        :comments => comment).
        reserve(self.showdate, logged_in_customer)
    end
  end

  def promo_code_matches(str = nil)
    str.to_s.contained_in_or_blank(self.promo_code)
  end

  private

  # return true if this valid_voucher should be displayed based on promo_code.
  # that is, if it has no associated promo code, OR if the supplied string
  # matches one of the associated promo codes.
  
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
      return cust.subscriber?
    when 2
      return true
    else
      raise "Unknown value #{av.vouchertype.offer_public} for offer_public"
    end
  end


  def self.sold_out_or_date_invalid(sd,ignore_cutoff)
    now = Time.now
    if sd.saleable_seats_left < 1
      "Performance is sold out"
    elsif  sd.thedate < now && !sd.show.special && !ignore_cutoff
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
        [0, "Tickets go on sale #{v.start_sales.to_formatted_s(:month_day_only)}"]
      else
        [howmany, "available"]
      end
    else                      # ignore date constraints
      [howmany, "available"]
    end
  end

end
