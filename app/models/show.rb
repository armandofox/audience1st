class Show < ActiveRecord::Base

  REGULAR_SHOW = 'Regular Show'
  TYPES = [REGULAR_SHOW, 'Special Event', 'Class', 'Subscription']

  has_many :showdates, -> { order('thedate') }, :dependent => :destroy
  has_one :latest_showdate, -> { order('thedate DESC') }, :class_name => 'Showdate'
  has_many :vouchers, -> { joins(:vouchertype).merge(Voucher.finalized).merge(Vouchertype.seat_vouchertypes) }, :through => :showdates
  has_many :imports
  
  validates_presence_of :listing_date
  validates_inclusion_of :event_type, :in => Show::TYPES
  validates_length_of :name,                   :within => 1..255
  validates_length_of :description,            :maximum => 255
  validates_length_of :landing_page_url,       :maximum => 255
  validates_length_of :sold_out_customer_info, :maximum => 255
  validates_length_of :patron_notes,           :maximum => 255

  attr_accessible :name, :patron_notes, :landing_page_url
  attr_accessible :listing_date, :description, :event_type, :sold_out_dropdown_message, :sold_out_customer_info

  scope :current_and_future, -> {
    joins(:showdates).
    where('showdates.thedate >= ?', 1.day.ago).
    select('DISTINCT shows.*').
    order('listing_date')
  }

  def opening_date
    showdates.empty? ? listing_date : showdates.order('thedate').first.thedate.to_date
  end

  def closing_date
    showdates.empty? ? listing_date : showdates.order('thedate DESC').first.thedate.to_date
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
  
  def season
    # latest season that contains opening date
    self.opening_date.at_beginning_of_season.year
  end

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
