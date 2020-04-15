class Showdate < ActiveRecord::Base

  include Comparable
  
  belongs_to :show
  belongs_to :seatmap
  
  delegate :patron_notes, :name, :event_type, :to => :show

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

  validates :max_advance_sales, :numericality => { :greater_than_or_equal_to => 0, :only_integer => true }
  validates :house_capacity, :numericality => { :greater_than => 0, :only_integer => true }, :unless => :has_reserved_seating?
  validates_associated :show
  validates :thedate, :presence => true, :uniqueness => {:scope => :show_id, :message => "is already a performance for this show"}

  validates :end_advance_sales, presence: true
  validates :description, :length => {:maximum => 255}, :allow_blank => true
  validates :access_instructions, :presence => true, :if => :stream?

  validate :cannot_change_seating_type_if_existing_reservations, :on => :update
  validate :seatmap_can_accommodate_existing_reservations, :on => :update
  validate :at_most_one_stream_anytime_performance

  attr_accessible :thedate, :house_capacity, :end_advance_sales, :max_advance_sales, :description, :show_id, :seatmap_id

  require_dependency 'showdate/sales_reporting'
  require_dependency 'showdate/menu_descriptions'



  # round off all showdates to the nearest minute
  before_save :truncate_showdate_to_nearest_minute

  # virtually every dereference of a Showdate also accesses its Show,
  #  so set that up here to avoid n+1 query problems
  default_scope { includes(:show) }

  scope :general_admission, -> { where(:seatmap_id => nil) }
  scope :reserved_seating,  -> { where.not(:seatmap_id => nil) }

  def has_reserved_seating? ; !stream?  &&  !!seatmap ; end
  
  private

  def truncate_showdate_to_nearest_minute
    self.thedate.change(:sec => 0)
  end

  #  validations

  def at_most_one_stream_anytime_performance
    if stream_anytime? &&  show.reload.showdates.any?(&:stream_anytime?)
      self.errors.add(:base,
        I18n.translate('showdates.errors.already_has_stream_anytime'))
    end
  end

  def cannot_change_seating_type_if_existing_reservations
    return if total_sales.empty?
    errors.add(:base, I18n.translate('showdates.errors.cannot_change_seating_type')) if (seatmap_id_was.nil? && !seatmap_id.nil?) || (!seatmap_id_was.blank? && seatmap_id.blank?)
  end
  
  def seatmap_can_accommodate_existing_reservations
    return if seatmap.blank?
    cannot_accommodate = seatmap.cannot_accommodate(self.vouchers)
    unless cannot_accommodate.empty?
      self.errors.add(:base,
        I18n.translate('showdates.errors.cannot_change_seatmap') +  '<br/>' + 
        ApplicationController.helpers.vouchers_sorted_by_seat(cannot_accommodate))
    end
  end

  public

  Showdate::Sales = Struct.new(:vouchers, :revenue_per_seat, :total_offered_for_sale)

  def self.with_reserved_seating_json(shows = Show.all)
    (shows.nil? || shows.empty?) ? Showdate.none:
    Showdate.joins(:show).
      where('seatmap_id IS NOT NULL').
      where(:show_id => shows.map(&:id)).
      map(&:id).to_json
  end

  def valid_vouchers_for_walkup
    self.valid_vouchers.
      includes(:vouchertype).
      references(:vouchertype).
      where(:vouchertypes => {:walkup_sale_allowed => true}).
      order('vouchertypes.display_order')
  end

  # builders used by controller

  def self.from_date_list(dates, params)
    notice = ''
    sales_cutoff = params[:advance_sales_cutoff].to_i
    max_advance_sales = params[:max_advance_sales].to_i
    description = params[:description].to_s
    seatmap_id = if params[:seatmap_id].to_i.zero? then nil else params[:seatmap_id].to_i end
    house_capacity = if seatmap_id then 0 else params[:house_capacity].to_i end
    show = Show.find(params[:show_id])
    new_showdates = dates.map do |date|
      show.showdates.build(:thedate => date,
        :max_advance_sales => max_advance_sales,
        :end_advance_sales => date - sales_cutoff.minutes,
        :seatmap_id => seatmap_id,
        :house_capacity => house_capacity,
        :description => description)
    end
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

  # pseudo-accessors

  def stream?
    live_stream? || stream_anytime?
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

  # For general admission shows, use the specified house cap; for reserved seating,
  #  it shoudl be derived from the seatmap
  def house_capacity
    has_reserved_seating? ? seatmap.seat_count : attributes['house_capacity']
  end

  def can_accommodate?(seat)
    !has_reserved_seating? ||  seat.blank?  ||  seatmap.includes_seat?(seat)
  end
end

