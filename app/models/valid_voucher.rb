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

  class InvalidRedemptionError < RuntimeError ;  end
  class InvalidProcessedByError < RuntimeError ; end

  attr_accessible :showdate_id, :showdate, :vouchertype_id, :vouchertype, :promo_code, :start_sales, :end_sales, :max_sales_for_type
  # auxiliary attributes that aren't persisted
  attr_accessible :explanation, :visible, :supplied_promo_code, :customer, :max_sales_for_this_patron
  belongs_to :showdate
  belongs_to :vouchertype
  validate :self_service_comps_must_have_promo_code
  validates_associated :showdate, :if => lambda { |v| !(v.vouchertype.bundle?) }
  validates_associated :vouchertype
  validates_numericality_of :max_sales_for_type, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_presence_of :start_sales
  validates_presence_of :end_sales

  scope :sorted, -> { joins(:vouchertype).order('vouchertypes.display_order,vouchertypes.name') }

  # Capacity is infinite if it is left blank
  INFINITE = 100_000
  def max_sales_for_type ; self[:max_sales_for_type] || INFINITE ; end
  def sales_unlimited?   ; max_sales_for_type >= INFINITE ; end

  validate :check_dates

  # for a given showdate ID, a particular vouchertype ID should be listed only once.
  validates_uniqueness_of :vouchertype_id, :scope => :showdate_id, :message => "already valid for this performance", :unless => lambda { |s| s.showdate_id.nil? }

  attr_accessor :customer, :supplied_promo_code # used only when checking visibility - not stored
  attr_accessor :explanation # tells customer/staff why the # of avail seats is what it is
  attr_accessor :visible     # should this offer be viewable by non-admins?
  alias_method :visible?, :visible # for convenience and more readable specs

  delegate :name, :price, :name_with_price, :display_order, :visible_to?, :season, :offer_public, :offer_public_as_string, :category, :comp?, :subscriber_voucher?, :to => :vouchertype
  delegate :<=>, :printable_name, :printable_date, :printable_date_with_description, :menu_selection_name, :name_and_date_with_capacity_stats, :saleable_seats_left, :thedate, :to => :showdate

  scope :for_shows, -> { where.not(:showdate => nil) }

  def public?
    [Vouchertype::SUBSCRIBERS, Vouchertype::ANYONE].include?(offer_public)
  end

  def event_type
    showdate.try(:show).try(:event_type)
  end

  def show_name
    showdate &&  showdate.show_name
  end

  attr_writer :max_sales_for_this_patron
  def max_sales_for_this_patron
    return @max_sales_for_this_patron.to_i if @max_sales_for_this_patron
    @max_sales_for_this_patron ||= max_sales_for_type()
    if showdate # in case this is a valid-voucher for a bundle, vs for regular show
      [@max_sales_for_this_patron, showdate.saleable_seats_left.to_i].min
    else
      @max_sales_for_this_patron.to_i
    end
  end

  private

  # A zero-price vouchertype that is marked as "available to public"
  # MUST have a promo code
  def self_service_comps_must_have_promo_code
    if vouchertype.self_service_comp? &&  promo_code.blank?
      errors.add(:promo_code, "must be provided for comps that are available for self-purchase")
    end
  end

  # Vouchertype's valid date must not be later than valid_voucher start date
  # Vouchertype expiration date must not be earlier than valid_voucher end date
  def check_dates
    return if start_sales.blank? || end_sales.blank? || vouchertype.nil?
    errors.add(:base,"Start sales time cannot be later than end sales time") and return if start_sales > end_sales
    vt = self.vouchertype
    if self.end_sales > (end_of_season = Time.current.at_end_of_season(vt.season))
      errors.add :base, "Voucher type '#{vt.name}' is valid for the
        season ending #{end_of_season.to_formatted_s(:showtime_including_year)},
        but you've indicated sales should continue later than that
        (until #{end_sales.to_formatted_s(:showtime_including_year)})."
    end
    self.end_sales = self.end_sales.rounded_to(:second)
  end

  def match_promo_code(str)
    promo_code.blank? || str.to_s.contained_in_or_blank(promo_code)
  end

  protected

  def adjust_for_visibility
    if !match_promo_code(supplied_promo_code)
      self.explanation = "Promo code #{promo_code.to_s.upcase} required"
      self.visible = false
    elsif !visible_to?(customer)
      self.explanation = "Ticket sales of this type restricted to #{offer_public_as_string}"
      self.visible = false
    end
    self.max_sales_for_this_patron = 0 if !self.explanation.blank?
    !self.explanation.blank?
  end

  def adjust_for_showdate
    if !showdate
      self.max_sales_for_this_patron = 0
      return nil
    end
    if showdate.thedate < Time.current
      self.explanation = 'Event date is in the past'
      self.visible = false
    elsif showdate.sold_out?
      self.explanation = 'Event is sold out'
      self.visible = true
    end
    self.max_sales_for_this_patron = 0 if !self.explanation.blank?
    !self.explanation.blank?
  end

  def adjust_for_sales_dates
    now = Time.current
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
    self.max_sales_for_this_patron = 0 if !self.explanation.blank?
    !self.explanation.blank?
  end

  def adjust_for_advance_reservations
    if Time.current > end_sales
      self.explanation = 'Advance reservations for this performance are closed'
      self.max_sales_for_this_patron = 0
    end
    !self.explanation.blank?
  end

  def adjust_for_capacity
    self.max_sales_for_this_patron = seats_of_type_remaining()
    self.explanation =
      case max_sales_for_this_patron
      when 0 then "No seats remaining for tickets of this type"
      when INFINITE then "No performance-specific limit applies"
      else "#{max_sales_for_this_patron} remaining"
      end
    self.visible = true
  end

  def clone_with_id
    result = self.clone
    result.id = self.id # necessary since views expect valid-vouchers to have an id...
    result.visible = true
    result.customer = customer
    result.max_sales_for_this_patron = seats_of_type_remaining
    result.explanation = ''
    result
  end

  public
  
  def seats_of_type_remaining
    unless showdate
      self.explanation = "No limit"
      return INFINITE unless showdate
    end
    total_empty = showdate.saleable_seats_left
    remain = if sales_unlimited? # no limit on ticket type: only limit is show capacity
             then total_empty
             else  [[max_sales_for_type - showdate.sales_by_type(vouchertype_id), 0].max, total_empty].min
             end
    remain = [remain, 0].max    # make sure it's positive
  end

  def self.bundles(seasons = [Time.this_season-1, Time.this_season+1])
    ValidVoucher.
      includes(:vouchertype,:showdate).references(:vouchertypes).
      where('vouchertypes.category' => 'bundle').
      where('vouchertypes.season IN (?)', seasons).
      order("season DESC,display_order,price DESC")
  end

  def self.bundles_available_to(customer = Customer.walkup_customer, promo_code=nil)
    bundles = ValidVoucher.
      where('? BETWEEN start_sales AND end_sales', Time.current).
      includes(:vouchertype,:showdate).references(:vouchertypes).
      where('vouchertypes.category' => 'bundle').
      order("season DESC,display_order,price DESC")
    bundles = bundles.map do |b|
      b.customer = customer
      b.supplied_promo_code = promo_code
      b.adjust_for_customer
    end
    bundles.reject! { |b| b.max_sales_for_this_patron == 0 }
    bundles.sort_by(&:display_order)
  end

  # returns a copy of this ValidVoucher, but with max_sales_for_this_patron adjusted to
  # the number of tickets of THIS vouchertype for THIS show available to
  # THIS customer.
  def adjust_for_customer
    result = self.clone_with_id
    # boxoffice and higher privilege can do anything
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
    # boxoffice and higher privilege can do anything
    result.adjust_for_showdate ||
      result.adjust_for_advance_reservations ||
      result.adjust_for_capacity # this one must be called last
    result.freeze
  end

  #  This display helper is called to display menus visible to patron,
  #  so the valid-voucher in question has had its max_sales_for_this_patron ADJUSTED ALREADY
  #  to the value applicable for THIS PATRON, which may be DIFFERENT from the value
  #  specified for the valid-voucher's max_sales_for_type originally.
  def name_with_explanation
    showdate.printable_name << with_explanation
  end

  def date_with_explanation
    showdate.printable_date_with_description << with_explanation
  end

  def with_explanation
    max_sales_for_this_patron.zero? ? " (Not available)" : ""
  end
  
  def explanation_for_admin
    m = max_sales_for_this_patron 
    if  m > 0
      "#{m} available"
    else
      "Not available for this patron"
    end
  end

  def date_with_explanation_for_admin
    "#{showdate.printable_date_with_description} (#{explanation_for_admin})"
  end

  def name_with_explanation_for_admin
    "#{showdate.printable_name} (#{explanation_for_admin})"
  end

  def show_name_with_seats_of_type_remaining
    "#{showdate.printable_name} (#{seats_of_type_remaining} left)"
  end

  def show_name_with_vouchertype_name
    "#{showdate.printable_name} - #{vouchertype.name}"
  end

  def instantiate(quantity)
    raise InvalidProcessedByError unless customer.kind_of?(Customer)
    vouchers = VoucherInstantiator.new(vouchertype,:promo_code => self.promo_code).from_vouchertype(quantity)
    # if vouchertype was a bundle, check whether any of its components
    #   are monogamous, if so reserve them
    if vouchertype.bundle?
      try_reserve_for_unique(vouchers)
      # if the original vouchertype was NOT a bundle, we have a bunch of regular vouchers.
      #   if a showdate was given OR the vouchers are monogamous, reserve them.
    elsif (theshowdate = self.showdate || vouchertype.unique_showdate)
      try_reserve_for(vouchers, theshowdate)
    end
    vouchers
  end

  def try_reserve_for_unique(vouchers)
    vouchers.each do |v|
      v.reserve_for(showdate, customer) if (showdate = v.unique_showdate)
    end
  end

  def try_reserve_for(vouchers, showdate)
    vouchers.each do |v|
      v.reserve_for(showdate, customer)
    end
  end

end
