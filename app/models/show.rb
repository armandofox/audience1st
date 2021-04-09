class Show < ActiveRecord::Base

  REGULAR_SHOW = 'Regular Show'
  TYPES = [REGULAR_SHOW, 'Special Event', 'Class', 'Subscription']

  REMINDERS = ['Never', '12 hours before curtain time', '24 hours before curtain time', '36 hours before curtain time', '48 hours before curtain time']

  has_many :showdates, -> { order('thedate') }, :dependent => :destroy
  has_one :latest_showdate, -> { order('thedate DESC') }, :class_name => 'Showdate'
  has_many :vouchers, -> { joins(:vouchertype).merge(Voucher.finalized).merge(Vouchertype.seat_vouchertypes) }, :through => :showdates
  has_many :imports
  
  validates_presence_of :listing_date
  validates_presence_of :season
  validates :season, :presence => true, :numericality => {:greater_than_or_equal_to => 1900}
  validates_inclusion_of :event_type, :in => Show::TYPES
  validates_inclusion_of :reminder_type, :in => Show::REMINDERS
  validates_length_of :name,                   :within => 1..255
  validates_length_of :description,            :maximum => 255
  validates_length_of :landing_page_url,       :maximum => 255
  validates_length_of :sold_out_customer_info, :maximum => 255
  validates_length_of :patron_notes,           :maximum => 255

  scope :current_and_future, -> {
    joins(:showdates).
    where('showdates.thedate >= ?', 1.day.ago).
    select('DISTINCT shows.*').
    order('listing_date')
  }

  scope :for_seasons, ->(from,to) {  where(:season => from..to) }
  
  def opening_date
    first_showdate = showdates.order('thedate').first
    first_showdate ? first_showdate.thedate.to_date : listing_date
  end

  def closing_date
    last_showdate = showdates.reorder('thedate' => :desc).first
    last_showdate ? last_showdate.thedate.to_date : listing_date
  end

  def upcoming_showdates
    # showdates for which there is at least one ValidVoucher that is still on sale,
    #   sorted in order of curtain time
    showdates.
      includes(:valid_vouchers).references('valid_vouchers').
      where('valid_vouchers.end_sales >= ?', Time.current).
      order(:thedate)
  end

  def special? ; event_type != 'Regular Show' ; end
  def special ; special? ; end

  def self.type(arg)
    TYPES.include?(arg) ? arg : REGULAR_SHOW
  end
  
  scope :of_type, ->(type) {
    where('event_type = ?', self.type(type))
  }
  
  def special? ; event_type != 'Regular Show' ; end
  def special ; special? ; end

  def revenue
    vouchers.map(&:amount).sum
  end

  def revenue_per_seat
    n = vouchers.count
    n.zero? ? 0.0 : (revenue.to_f / n)
  end

  def capacity
    self.showdates.sum(:house_capacity)
  end

  def percent_sold
    showdates.size.zero? ? 0.0 :
      showdates.inject(0) { |t,s| t+s.percent_sold } / showdates.size
  end

  def percent_of_house
    showdates.size.zero? ? 0.0 :
      showdates.inject(0) { |t,s| t+s.percent_of_house } / showdates.size
  end

  def total_sales
    showdates.map(&:total_sales).flatten
  end

  def max_advance_sales
    showdates.inject(0) { |t,s| t+s.max_advance_sales }
  end

  def total_offered_for_sale ; showdates.sum(:house_capacity) ; end

  def menu_selection_name ; name ; end

  def name_with_description
    description.blank? ? name : "#{name} (#{description})"
  end

  def run_dates
    "#{opening_date.to_formatted_s(:month_day_only)} - #{closing_date.to_formatted_s(:month_day_only)}"
  end

  def name_with_run_dates ; "#{name} - #{run_dates}" ; end

  def name_with_run_dates_short
    s = self.opening_date
    e = self.closing_date
    if s.year == e.year
      dt = (s.month == e.month)? s.strftime('%b %Y') :
        "#{s.strftime('%b')} - #{e.strftime('%b %Y')}"
    else                        # different years
      dt = "#{s.strftime('%b %Y')} - #{e.strftime('%b %Y')}"
    end
    "#{self.name} (#{dt})"
  end

  def self.find_unique(name)
    Show.where('name LIKE ?', name.strip).first
  end

end
