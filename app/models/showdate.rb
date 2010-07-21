class Showdate < ActiveRecord::Base

  include Comparable

  belongs_to :show
  has_many :vouchers, :conditions => "vouchers.category != 'nonticket'"
  has_many :vouchertypes, :through => :vouchers, :uniq => true
  has_many :all_vouchers, :class_name => 'Voucher'
  has_many :valid_vouchers, :dependent => :destroy

  validates_numericality_of :max_sales, :greater_than_or_equal_to => 0
  validates_associated :show
  validates_presence_of :end_advance_sales
  validates_length_of :description, :maximum => 20, :allow_nil => true
  
  validates_uniqueness_of :thedate, :scope => :show_id,
  :message => "is already a performance for this show"

  # round off all showdates to the nearest minute
  before_save :truncate_showdate_to_nearest_minute

  private

  def truncate_showdate_to_nearest_minute
    self.thedate.change(:sec => 0)
  end

  public

  # create new showdate (for use by imports/daemons)

  def self.placeholder(thedate)
    Showdate.new(:thedate => thedate,
      :end_advance_sales => thedate,
      :max_sales => 0)
  end
      

  # finders
  
  def self.current_and_future
    Showdate.find(:all, :conditions => ["thedate >= ?", Time.now - 1.day],
      :order => 'thedate')
  end

  def self.current_or_next(buffer = 0)
    Showdate.find(:first, :conditions => ["thedate >= ?", Time.now - buffer],
      :order => "thedate")
  end

  def self.next_or_latest
    Showdate.current_or_next || Showdate.find(:first, :order => "thedate DESC")
  end

  def self.all_shows_this_season
    Showdate.find(:all, :order => 'thedate ASC',
                  :conditions => ['thedate BETWEEN ? and ?',
                                  Time.now.at_beginning_of_season,
                                  Time.now.at_end_of_season])
  end

  # to support Store views for which showdates to display

  def ok_to_display_for?(who = Customer.generic_customer)
    unless who.kind_of?(Customer)
      who = Customer.find_by_id(who)
      return nil unless who.kind_of?(Customer)
    end
    # is showdate in past?  if so, only Boxoffice users can see
    return who.is_boxoffice if self.thedate < Time.now
  end

  # reporting, comparisons
  
  def <=>(other_showdate)
    other_showdate ? thedate <=> other_showdate.thedate : 1
  end

  def sales_by_type(vouchertype_id)
    return self.vouchers.count(:conditions => ['vouchertype_id = ?', vouchertype_id])
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.price}
  end

  def revenue
    self.vouchers.inject(0) {|sum,v| sum + v.price}
  end

  def revenue_per_seat
    revenue / (comp_seats + nonsubscriber_revenue_seats)
  end

  def comp_seats
    self.vouchers.count(:conditions => ['category = ?', :comp])
  end

  def nonsubscriber_revenue_seats
    self.vouchers.count(:conditions => ['category = ?', :revenue])
  end

  def subscriber_seats
    self.vouchers.count(:conditions => ['category = ?', :subscriber])
  end

  def advance_sales?
    (self.end_advance_sales - 5.minutes) > Time.now
  end

  def house_capacity ;   self.show.house_capacity ;  end

  def max_allowed_sales
    self.max_sales.zero? ? self.house_capacity : [self.max_sales,self.house_capacity].min
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

  def percent_of(cap)
    cap.to_f == 0.0 ?  0 : (100.0 * compute_total_sales / cap).floor
  end
      

  # percent of max sales: may exceed 100
  def percent_sold
    percent_of(max_allowed_sales)
  end

  # percent of house: may exceed 100
  def percent_of_house
    percent_of(house_capacity)
  end

  def sold_out? ; percent_sold.to_i >= Option.value(:sold_out_threshold).to_i ; end

  def nearly_sold_out? ; percent_sold.to_i >= Option.value(:nearly_sold_out_threshold).to_i ; end

  def availability_in_words
    pct = percent_sold
    pct >= Option.value(:sold_out_threshold).to_i ?  :sold_out :
      pct >= Option.value(:nearly_sold_out_threshold).to_i ? :nearly_sold_out :
      :available
  end

  def compute_total_sales
    self.vouchers.count
  end

  def compute_advance_sales
    self.vouchers.count(:conditions => ['customer_id != ?', Customer.walkup_customer.id])
  end

  def checked_in
    self.vouchers.count(:conditions => ['used = ?', true])
  end

  def spoken_name
    self.show.name.gsub( /\W/, ' ')
  end

  def speak
    self.spoken_name + ", on " + self.thedate.speak
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
  
  def menu_selection_name ; printable_date_with_description ; end
    
end
