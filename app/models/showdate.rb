class Showdate < ActiveRecord::Base
  
  belongs_to :show
  has_many :vouchers
  has_many :valid_vouchers, :dependent => :destroy
  has_many :vouchertypes, :through => :valid_vouchers
  
  validates_numericality_of :max_sales
  validates_associated :show

  include Comparable
  def <=>(other_showdate)
    thedate <=> other_showdate.thedate
  end

  def sales_by_type(vouchertype_id)
    return Voucher.count(:conditions => ['showdate_id = ? AND vouchertype_id = ?', self.id, vouchertype_id])
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.price}
  end

  def revenue
    self.vouchers.inject(0) {|sum,v| sum + v.price}
  end

  def revenue_per_seat
    self.revenue / self.vouchers.length
  end

  def advance_sales?
    (self.end_advance_sales - 5.minutes) > Time.now
  end

  # capacity: if zero, then use show's capacity
  def capacity
    (self.max_sales <= 0 ?
     self.show.house_capacity :
     [self.max_sales, self.show.house_capacity].min )
  end

  def total_seats_left
    [self.capacity - self.compute_total_sales, 0].max
  end

  def percent_sold
    cap = self.capacity.to_f
    cap.zero? ? 0 : (100.0 * (cap - self.total_seats_left) / cap).floor
  end

  def availability_in_words
    pct = self.percent_sold
    if pct >= (APP_CONFIG[:sold_out_threshold] || 95)
      :sold_out
    elsif pct >= (APP_CONFIG[:nearly_sold_out_threshold] || 85)
      :nearly_sold_out
    else
      :available
    end
  end
  
  def seats_left_for_voucher(vouchertype,cust=Customer.generic_customer)
    ValidVoucher.numseats_for_showdate_by_vouchertype(self.id, vouchertype, cust)
  end

  def seats_left(cust=Customer.generic_customer)
    ValidVoucher.numseats_for_showdate(self.id, cust)
  end

  def compute_total_sales
    return Voucher.count(:conditions => ['showdate_id =  ?', self.id])
  end

  def spoken_name
    self.show.name.gsub( /\W/, ' ')
  end

  def speak
    self.spoken_name + ", on " + self.thedate.speak
  end
  
  def printable_name
    self.show.name + " - " + self.printable_date
  end

  def printable_date
    self.thedate.strftime('%A, %b %e, %I:%M%p')
  end
end
