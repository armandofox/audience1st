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

  # for a given showdate ID, a particular vouchertype ID should be listed only once.
  validates_uniqueness_of :vouchertype_id, :scope => :showdate_id, :message => "already valid for this performance"

  attr_accessor :customer, :supplied_promo_code # used only when checking visibility - not stored
  attr_accessor :explanation # tells customer/staff why the # of avail seats is what it is
  attr_accessor :visible     # should this offer be viewable by non-admins?
  alias_method :visible?, :visible # for convenience and more readable specs

  delegate :name, :price, :name_with_price, :display_order, :visible_to?, :season, :offer_public_as_string, :to => :vouchertype
  delegate :<=>, :printable_name, :thedate, :to => :showdate

  def event_type
    showdate.try(:show).try(:event_type)
  end

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

  def match_promo_code(str)
    promo_code.blank? || str.to_s.contained_in_or_blank(promo_code)
  end

  protected
  
  def adjust_for_visibility
    if !match_promo_code(supplied_promo_code)
      self.explanation = 'Promo code required'
      self.visible = false
    elsif !visible_to?(customer)
      self.explanation = "Ticket sales of this type restricted to #{offer_public_as_string}"
      self.visible = false
    end
    !self.explanation.blank?
  end

  def adjust_for_showdate
    if showdate.thedate < Clock.now
      self.explanation = 'Event date is in the past'
      self.visible = false
    elsif showdate.saleable_seats_left < 1
      self.explanation = 'Event is sold out'
      self.visible = true
    elsif showdate.end_advance_sales < Clock.now
      self.explanation = 'Advance sales for this event are closed'
      self.visible = true
    end
    !self.explanation.blank?
  end

  def adjust_for_sales_dates
    now = Clock.now
    if now < start_sales
      self.explanation = "Tickets of this type not on sale until #{start_sales.to_formatted_s(:showtime)}"
      self.visible = true
    elsif now > end_sales
      self.explanation = "Tickets of this type not sold after #{end_sales.to_formatted_s(:showtime)}"
      self.visible = true
    end
    !self.explanation.blank?
  end

  def adjust_for_capacity
    self.max_sales_for_type = seats_remaining
    self.explanation = "All tickets of this type have been sold" if max_sales_for_type.zero?
  end

  public

  def to_s
    sprintf "%s max %3d %s- %s %s", vouchertype, max_sales_for_type,
    start_sales.strftime('%c'), end_sales.strftime('%c'),
    promo_code
  end
  
  # returns a copy of this ValidVoucher, but with max_sales_for_type adjusted to
  # the number of tickets of THIS vouchertype for THIS show available to THIS customer.
  def adjust_for_customer(customer,customer_supplied_promo_code = '')
    result = self.clone
    result.id = self.id # necessary since views expect valid-vouchers to have an id...
    result.visible = true
    result.customer = customer
    result.supplied_promo_code = customer_supplied_promo_code.to_s
    result.explanation = ''
    result.max_sales_for_type = 0 # will be overwritten by correct answer
    result.adjust_for_visibility ||
      result.adjust_for_showdate ||
      result.adjust_for_sales_dates ||
      result.adjust_for_capacity
    result.freeze
  end

  named_scope :on_sale_now, :conditions => ['? BETWEEN start_sales AND end_sales', Time.now]


  def self.for_advance_sales(supplied_promo_code = '')
    general_conds = "? BETWEEN start_sales AND end_sales"
    general_opts = [Time.now]
    promo_code_conds = "promo_code IS NULL OR promo_code = ''"
    promo_code_opts = []
    unless promo_codes.empty?
      promo_code_conds += " OR promo_code LIKE ? " * promo_codes.length
    end
    ValidVoucher.find(:all,
      :conditions => ["#{general_conds} AND (#{promo_code_conds})", general_opts + promo_codes])
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

end
