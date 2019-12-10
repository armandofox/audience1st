class Showdate < ActiveRecord::Base

  include Comparable
  
  belongs_to :show
  belongs_to :seatmap
  
  delegate :house_capacity, :patron_notes, :name, :event_type, :to => :show

  has_many :vouchers, -> { joins(:vouchertype).merge(Vouchertype.seat_vouchertypes) }
  has_many :finalized_vouchers, -> { joins(:vouchertype).merge(Vouchertype.seat_vouchertypes).merge(Voucher.finalized) }, :class_name => 'Voucher'
  has_many :all_vouchers, :class_name => 'Voucher'
  has_many :walkup_vouchers, -> { where(:walkup => true) }, :class_name => 'Voucher'
  # Workaround for story #169936179
  # has_many :customers, -> { where('customers.role >= 0').uniq(true) }, :through => :vouchers
  #   -- though should really be ':through => :finalized_vouchers'
  def customers
    # result must be an ARel Relation, otherwise we'd just write:
    # finalized_vouchers.map(&:customer).uniq.select { |c| ! c.special_customer? }
    Customer.where('role >= 0').
      includes(:vouchers).where('items.finalized' => true).where('items.showdate_id' => self.id).
      joins(:vouchertypes).where('items.vouchertype_id = vouchertypes.id').
      where('vouchertypes.category != ?', 'nonticket').
      uniq(true)
  end
  has_many :vouchertypes, -> { uniq(true) }, :through => :vouchers
  has_many :available_vouchertypes, -> { uniq(true) }, :source => :vouchertype, :through => :valid_vouchers
  has_many :valid_vouchers, :dependent => :destroy

  validates_numericality_of :max_advance_sales, :greater_than_or_equal_to => 0
  validates_associated :show
  validates_presence_of :thedate
  validates_presence_of :end_advance_sales
  validates_length_of :description, :maximum => 32, :allow_nil => true
  
  attr_accessible :thedate, :end_advance_sales, :max_advance_sales, :description, :show_id, :seatmap_id
  attr_accessible :valid_vouchers

  require_dependency 'showdate/sales_reporting'
  require_dependency 'showdate/menu_descriptions'


  validates_uniqueness_of :thedate, :scope => :show_id,
  :message => "is already a performance for this show"

  # round off all showdates to the nearest minute
  before_save :truncate_showdate_to_nearest_minute

  # virtually every dereference of a Showdate also accesses its Show,
  #  so set that up here to avoid n+1 query problems
  default_scope { includes(:show) }

  scope :general_admission, -> { where(:seatmap_id => nil) }
  scope :reserved_seating,  -> { where.not(:seatmap_id => nil) }
  scope :blah, -> { joins(:valid_vouchers) }

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
      :max_advance_sales => 0)
  end

  def self.with_reserved_seating_json(shows = Show.all)
    (shows.nil? || shows.empty?) ? Showdate.none:
    Showdate.joins(:show).
      where('seatmap_id IS NOT NULL').
      where(:show_id => shows.map(&:id)).
      map(&:id).to_json
  end

  def valid_vouchers_for_walkup
    self.valid_vouchers.includes(:vouchertype).select { |vv| vv.vouchertype.walkup_sale_allowed? }
  end

  # finders
  
  def self.current_and_future
    Showdate.where("thedate >= ?", Time.current - 1.day).order('thedate')
  end

  def self.current_or_next(opts={})
    buffer = opts[:grace_period] || 0
    type = opts[:type] || 'Regular Show'
    Showdate.
      includes(:show).references(:shows).
      where("showdates.thedate >= ? AND shows.event_type=?",Time.current-buffer, type).
      order("thedate").
      first  ||

      Showdate.
      includes(:show).references(:shows).
      where("shows.event_type = ?", type).
      order('thedate DESC').
      first
  end

  def self.all_showdates_for_seasons(first=Time.current.year, last=Time.current.year)
    first = Time.current.at_beginning_of_season(first)
    last = Time.current.at_end_of_season(last)
    Showdate.where('thedate BETWEEN ? and ?', first, last).order('thedate')
  end

  def inspect
    "#{self.id} #{name_and_date_with_capacity_stats}/#{max_advance_sales}"
  end
  
  def <=>(other_showdate)
    other_showdate ? thedate <=> other_showdate.thedate : 1
  end

  def season
    thedate.this_season
  end

  def advance_sales_open?
    valid_vouchers.any? { |vv| Time.current >= vv.start_sales }
  end
  
  def duration
    # for now a fixed amount.  in future may be settable
    150.minutes
  end

  # Calculation of available seats (for reserved seating)
  def occupied_seats
    return [] unless seatmap
    # basically, collect seat info from all vouchers for this showdate
    vouchers.map(&:seat).compact.map(&:to_s).sort
  end
end

