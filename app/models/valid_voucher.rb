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
  delegate :<=>, :printable_name, :thedate, :saleable_seats_left, :to => :showdate

  def event_type
    showdate.try(:show).try(:event_type)
  end

  def self.from_params(valid_vouchers_hash)
    result = {}
    (valid_vouchers_hash || {}).each_pair do |id,qty|
      if ((vv = self.find_by_id(id)) &&
          ((q = qty.to_i) > 0))
        result[vv] = q
      end
    end
    result
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
        season ending #{end_of_season.to_formatted_s(:showtime)},
        but you've indicated sales should continue later than that
        (until #{end_sales.to_formatted_s(:showtime)})."
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
    return nil if !showdate
    if showdate.thedate < Clock.now
      self.explanation = 'Event date is in the past'
      self.visible = false
    elsif showdate.really_sold_out?
      self.explanation = 'Event is sold out'
      self.visible = true
    end
    !self.explanation.blank?
  end

  def adjust_for_sales_dates
    now = Clock.now
    if showdate && (now > showdate.end_advance_sales)
      self.explanation = 'Advance sales for this performance are closed'
      self.visible = true
    elsif now < start_sales
      self.explanation = "Tickets of this type not on sale until #{start_sales.to_formatted_s(:showtime)}"
      self.visible = true
    elsif now > end_sales
      self.explanation = "Tickets of this type not sold after #{end_sales.to_formatted_s(:showtime)}"
      self.visible = true
    end
    !self.explanation.blank?
  end

  def adjust_for_advance_reservations
    if Clock.now > end_sales
      self.explanation = 'Advance reservations for this performance are closed'
      self.max_sales_for_type = 0
    end
    !self.explanation.blank?
  end

  def adjust_for_capacity
    if !showdate
      self.explanation = "No performance-specific limit applies"
      return
    end
    self.max_sales_for_type = seats_of_type_remaining()
    self.explanation =
      if max_sales_for_type.zero?
      then "No seats remaining for tickets of this type"
      else "#{max_sales_for_type} of these tickets remaining"
      end
  end



  def clone_with_id
    result = self.clone
    result.id = self.id # necessary since views expect valid-vouchers to have an id...
    result.visible = true
    result.customer = customer
    result.explanation = ''
    result
  end
  
  public

  def to_s
    sprintf "%s max %3d %s- %s %s", vouchertype, max_sales_for_type,
    start_sales.strftime('%c'), end_sales.strftime('%c'),
    promo_code
  end
  
  def seats_of_type_remaining
    total_empty = showdate.saleable_seats_left
    return 1e6 unless showdate
    remain = if max_sales_for_type.zero? # no limit on ticket type: only limit is show capacity
             then total_empty
             else  [[max_sales_for_type - showdate.sales_by_type(vouchertype_id), 0].max, total_empty].min
             end
    remain = [remain, 0].max    # make sure it's positive
  end

  # returns a copy of this ValidVoucher, but with max_sales_for_type adjusted to
  # the number of tickets of THIS vouchertype for THIS show available to THIS customer.
  def adjust_for_customer(customer_supplied_promo_code = '')
    result = self.clone_with_id
    result.supplied_promo_code = customer_supplied_promo_code.to_s
    result.adjust_for_visibility ||
      result.adjust_for_showdate ||
      result.adjust_for_sales_dates ||
      result.adjust_for_capacity # this one must be called last
    result.freeze
  end

  # returns a copy of this ValidVoucher for a voucher *that the customer already has*
  #  but adjusted to see if it can be redeemed
  def adjust_for_customer_reservation
    result = self.clone_with_id
    result.adjust_for_showdate ||
      result.adjust_for_advance_reservations ||
      result.adjust_for_capacity # this one must be called last
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

  def date_with_explanation
    display_name = showdate.menu_selection_name
    max_sales_for_type > 0 ? display_name : "#{display_name} (#{explanation})"
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
      v = Voucher.new_from_vouchertype(
        self.vouchertype,
        :purchasemethod => purchasemethod,
        :comments => comment)
      v.reserve(showdate, logged_in_customer) if showdate
      v
    end
  end

end
