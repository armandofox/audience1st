class Showdate < ActiveRecord::Base

  include Comparable
  
  belongs_to :show

  delegate :house_capacity, :patron_notes, :name, :to => :show

  has_many :vouchers, -> { where.not(:category => 'nonticket') }
  has_many :all_vouchers, :class_name => 'Voucher'
  has_many :walkup_vouchers, -> { where(:walkup => true) }, :class_name => 'Voucher'
  has_many :customers, -> { where('customers.role >= 0').uniq(true) }, :through => :vouchers
  has_many :vouchertypes, -> { uniq(true) }, :through => :vouchers
  has_many :available_vouchertypes, -> { uniq(true) }, :source => :vouchertype, :through => :valid_vouchers
  has_many :valid_vouchers, :dependent => :destroy

  validates_numericality_of :max_sales, :greater_than_or_equal_to => 0
  validates_associated :show
  validates_presence_of :thedate
  validates_presence_of :end_advance_sales
  validates_length_of :description, :maximum => 32, :allow_nil => true
  
  attr_accessible :thedate, :end_advance_sales, :max_sales, :description, :show_id

  validates_uniqueness_of :thedate, :scope => :show_id,
  :message => "is already a performance for this show"

  # round off all showdates to the nearest minute
  before_save :truncate_showdate_to_nearest_minute

  # virtually every dereference of a Showdate also accesses its Show,
  #  so set that up here to avoid n+1 query problems
  default_scope { includes(:show) }

  private

  def truncate_showdate_to_nearest_minute
    self.thedate.change(:sec => 0)
  end

  public

  Showdate::Sales = Struct.new(:vouchers, :revenue_per_seat, :total_offered_for_sale)

  # create new showdate (for use by imports/daemons)

  def self.placeholder(thedate)
    Showdate.new(:thedate => thedate,
      :end_advance_sales => thedate,
      :max_sales => 0)
  end

  def valid_vouchers_for_walkup
    self.valid_vouchers.includes(:vouchertype).select { |vv| vv.vouchertype.walkup_sale_allowed? }
  end

  # finders
  
  def self.current_and_future
    Showdate.where("thedate >= ?", Time.now - 1.day).order('thedate')
  end

  def self.current_or_next(opts={})
    buffer = opts[:grace_period] || 0
    type = opts[:type] || 'Regular Show'
    Showdate.
      includes(:show).references(:shows).
      where("showdates.thedate >= ? AND shows.event_type=?",Time.now-buffer, type).
      order("thedate").
      first  ||

      Showdate.
      includes(:show).references(:shows).
      where("shows.event_type = ?", type).
      order('thedate DESC').
      first
  end

  def self.all_showdates_for_seasons(first=Time.now.year, last=Time.now.year)
    first = Time.now.at_beginning_of_season(first)
    last = Time.now.at_end_of_season(last)
    Showdate.where('thedate BETWEEN ? and ?', first, last).order('thedate')
  end

  # reporting, comparisons

  def inspect
    "#{self.id} #{name_and_date_with_capacity_stats}/#{max_allowed_sales}"
  end
  
  def <=>(other_showdate)
    other_showdate ? thedate <=> other_showdate.thedate : 1
  end

  def season
    thedate.this_season
  end
  
  def sales_by_type(vouchertype_id)
    return self.vouchers.where('vouchertype_id = ?', vouchertype_id).count
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.amount.to_f}
  end

  def revenue
    self.vouchers.inject(0) {|sum,v| sum + v.amount.to_f}
  end

  def revenue_per_seat
    total_seated = comp_seats + nonsubscriber_revenue_seats
    if (revenue.zero? || total_seated.zero?) then 0.0 else revenue/total_seated end
  end

  def comp_seats
    self.vouchers.comp.count
  end

  def nonsubscriber_revenue_seats
    self.vouchers.revenue.count
  end

  def subscriber_seats
    self.vouchers.subscriber.count
  end

  def advance_sales?
    (self.end_advance_sales - 5.minutes) > Time.now
  end

  def max_allowed_sales
    self.max_sales
  end

  def total_offered_for_sale ; house_capacity ; end

  def percent_max_allowed_sales
    house_capacity.zero? ? 100.0 : 100.0 * max_allowed_sales / house_capacity
  end

  # release unsold seats from an external channel back to general inventory.
  # if show cap == house cap, this has no effect.
  # otherwise, show cap is boosted back up by the number of unsold seats,
  # but never higher than the house cap.

  def release_holdback(num)
    self.update_attribute(:max_sales, max_sales + num)
    max_sales
  end

  def total_seats_left
    [self.house_capacity - compute_total_sales, 0].max
  end

  def saleable_seats_left
    [self.max_allowed_sales - compute_total_sales, 0].max
  end

  def really_sold_out? ; saleable_seats_left < 1 ; end

  def percent_of(cap)
    cap.to_f == 0.0 ?  100 : (100.0 * compute_total_sales / cap).floor
  end

  # percent of max sales: may exceed 100
  def percent_sold
    percent_of(max_allowed_sales)
  end

  # percent of house: may exceed 100
  def percent_of_house
    percent_of(house_capacity)
  end

  def sold_out? ; really_sold_out? || percent_sold.to_i >= Option.sold_out_threshold ; end

  def nearly_sold_out? ; !sold_out? && percent_sold.to_i >= Option.nearly_sold_out_threshold ; end

  # returns two elements indicating the lowest-priced and highest-priced
  # publicly-available tickets.
  def price_range
    public_prices = valid_vouchers.select(&:public?).map(&:price)
    public_prices.empty? ? [] : [public_prices.min, public_prices.max]
  end

  def availability_grade
    sales = percent_sold.to_i
    if sales >= Option.sold_out_threshold then 0
    elsif sales >= Option.nearly_sold_out_threshold then 1
    elsif sales >= Option.limited_availability_threshold then 2
    else 3
    end
  end

  def availability_in_words
    pct = percent_sold
    pct >= Option.sold_out_threshold ?  :sold_out :
      pct >= Option.nearly_sold_out_threshold ? :nearly_sold_out :
      :available
  end

  def compute_total_sales
    self.vouchers.count
  end

  def advance_sales_vouchers
    self.vouchers.advance_sales
  end
  def compute_advance_sales
    self.vouchers.advance_sales.count
  end
  def compute_walkup_sales
    self.vouchers.walkup_sales.count
  end

  def checked_in
    self.vouchers.checked_in.count
  end
  def waiting_for
    [0, compute_advance_sales - checked_in].max
  end

  def printable_name
    self.show.name + " - " + self.printable_date_with_description
  end

  def printable_date
    self.thedate.to_formatted_s(:showtime)
  end

  def full_date
    self.thedate.to_formatted_s(:showtime_including_year)
  end

  def printable_date_with_description
    description.blank? ? printable_date : "#{printable_date} (#{description})"
  end

  def name_and_date_with_capacity_stats
    sprintf "#{printable_name} (%d)", compute_advance_sales
  end
  
  def menu_selection_name
    name = printable_date_with_description
    if sold_out?
      name = [name, show.sold_out_dropdown_message].join ' '
    elsif nearly_sold_out?
      name << " (Nearly Sold Out)"
    end
    name
  end

end

