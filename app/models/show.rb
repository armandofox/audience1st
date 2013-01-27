class Show < ActiveRecord::Base

  TYPES = ['Regular Show', 'Special Event', 'Class']

  acts_as_reportable
  
  has_many :showdates, :dependent => :destroy, :order => 'thedate'
  has_one :latest_showdate, :class_name => 'Showdate', :order => 'thedate DESC'
  # NOTE: We can't do the trick below because the database's timezone
  #  may not be the same as the appserver's timezone.
  #has_many :future_showdates, :class_name => 'Showdate', :conditions => 'end_advance_sales >= #{Time.db_now}'
  has_many :vouchers, :through => :showdates
  has_many :imports

  validates_presence_of :opening_date, :closing_date, :listing_date
  validates_inclusion_of :event_type, :in => Show::TYPES
  validates_length_of :name, :within => 3..40, :message =>
    "Show name must be between 3 and 40 characters"
  validates_numericality_of :house_capacity, :greater_than => 0

  # current_or_next returns the Show object corresponding to either the
  # currently running show, or the one with the next soonest opening date.

  def self.current_or_next
    Showdate.current_or_next.try(:show)
  end

  named_scope :current_and_future, lambda {
    {:joins => :showdates,
      :conditions => ['showdates.thedate >= ?', 1.day.ago],
      :order => 'opening_date ASC'
    }
  }

  def has_showdates? ; !showdates.empty? ; end
  
  def self.all_for_season(season=Time.this_season)
    startdate = Time.at_beginning_of_season(season)
    enddate = startdate + 1.year - 1.day
    Show.find(:all, :order => 'opening_date',
      :conditions => ['opening_date BETWEEN ? AND ?', startdate, enddate])
  end

  named_scope :all_for_seasons, lambda { |from,to|
    {:conditions =>  ['opening_date BETWEEN ? AND ?',
        Time.at_beginning_of_season(from), Time.at_end_of_season(to)] }
  }
  
  def special? ; event_type != 'Regular Show' ; end
  def special ; special? ; end

  named_scope :special, lambda { |value|
    if value
      {:conditions => ["event_type != ?", 'Regular Show']}
    else
      {:conditions => ["event_type = ?", 'Regular Show']}
    end
  }

  def season
    # latest season that contains opening date
    self.opening_date.at_beginning_of_season.year
  end

  def future_showdates
    self.showdates.find(:all,:conditions => ['end_advance_sales >= ?', Time.now],:order => 'thedate')
  end

  def special? ; event_type != 'Regular Show' ; end
  def special ; special? ; end

  def revenue ; self.vouchers.inject(0) {|sum,v| sum + v.price} ; end

  def revenue_per_seat
    v = self.vouchers.count("category NOT IN ('comp','subscriber')")
    v.zero? ? 0.0 : revenue / v
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.price}
  end

  def capacity
    self.showdates.inject(0) { |cap,sd| cap + sd.capacity }
  end

  def percent_sold
    showdates.size.zero? ? 0.0 :
      showdates.inject(0) { |t,s| t+s.percent_sold } / showdates.size
  end

  def percent_of_house
    showdates.size.zero? ? 0.0 :
      showdates.inject(0) { |t,s| t+s.percent_of_house } / showdates.size
  end

  def compute_total_sales
    showdates.inject(0) { |t,s| t+s.compute_total_sales }
  end

  def max_allowed_sales
    showdates.inject(0) { |t,s| t+s.max_allowed_sales }
  end

  def total_offered_for_sale ; showdates.length * house_capacity ; end

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
    Show.find(:first, :conditions => ['name LIKE ?', name.strip])
  end

  # return placeholder entity that will pass basic validations if saved
  
  def self.create_placeholder!(name)
    name = name.to_s
    name << "___" if name.length < 3
    Show.create!(:name => name,
      :opening_date => Date.today,
      :closing_date => Date.today + 1.day,
      :house_capacity => 1
      )
  end
  
  def adjust_metadata_from_showdates
    return if showdates.empty?
    dates = showdates.map(&:thedate)
    first,last = dates.min.to_date, dates.max.to_date
    self.opening_date = first if opening_date > first
    self.closing_date = last if closing_date < last
    return self.changed?
  end
      
end
