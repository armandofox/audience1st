class Showdate < ActiveRecord::Base

  include Comparable

  belongs_to :show
  has_many :vouchers
  has_many :valid_vouchers, :dependent => :destroy
  has_many :vouchertypes, :through => :valid_vouchers

  validates_numericality_of :max_sales
  validates_associated :show

  def self.current_or_next
    Showdate.find(:first, :conditions => "thedate >= NOW()")
  end

  def <=>(other_showdate)
    other_showdate ? thedate <=> other_showdate.thedate : 1
  end

  def sales_by_type(vouchertype_id)
    return Voucher.count(:conditions => ['showdate_id = ? AND vouchertype_id = ?', self.id, vouchertype_id])
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.price}
  end

  def revenue
    self.vouchers.sum('price')
  end

  def revenue_per_seat
    #self.revenue / self.vouchers.count("type!='SubscriberVoucher'")
    self.revenue / self.vouchers.count(:conditions => ['type != ?', SubscriberVoucher])
  end

  def comp_seats
    self.vouchers.count("type='CompVoucher'")
  end

  def nonsubscriber_revenue_seats
    self.vouchers.count("type='RevenueVoucher'")
  end

  def subscriber_seats
    self.vouchers.count("type='SubscriberVoucher'")
  end

  def advance_sales?
    (self.end_advance_sales - 5.minutes) > Time.now
  end

  def capacity ; max_sales ; end

  # release unsold seats from an external channel back to general inventory.
  # if show cap == house cap, this has no effect.
  # otherwise, show cap is boosted back up by the number of unsold seats,
  # but never higher than the house cap.

  def release_holdback(num)
    self.update_attribute(:max_sales, max_sales + num)
    max_sales
  end

  def total_seats_left
    [self.house_capacity - self.compute_total_sales, 0].max
  end

  def percent_sold
    cap = self.capacity.to_f
    cap.zero? ? 0 : (100.0 * (cap - self.total_seats_left) / cap).floor
  end

  def sold_out? ; percent_sold.to_i >= Option.value(:sold_out_threshold).to_i ; end

  def nearly_sold_out? ; percent_sold.to_i >= Option.value(:nearly_sold_out_threshold).to_i ; end

  def availability_in_words
    pct = percent_sold
    pct >= Option.value(:sold_out_threshold).to_i ?  :sold_out :
      pct >= Option.value(:nearly_sold_out_threshold).to_i ? :nearly_sold_out :
      :available
  end

  def seats_left_for_voucher(vouchertype,cust=Customer.generic_customer)
    ValidVoucher.numseats_for_showdate_by_vouchertype(self.id, vouchertype, cust)
  end

  def seats_left(cust=Customer.generic_customer)
    ValidVoucher.numseats_for_showdate(self.id, cust)
  end

  def no_seats_for(cust = Customer.generic_customer)
    cust ||= Customer.generic_customer
    self.seats_left(cust).all? { |av| av.howmany.zero? }
  end

  def compute_total_sales
    return Voucher.count(:conditions => ['showdate_id =  ?', self.id])
  end

  def compute_advance_sales
    return Voucher.count(:conditions => ['showdate_id = ? AND customer_id != ?',
                                        self.id, Customer.walkup_customer.id])
  end

  def checked_in
    return Voucher.count(:conditions => ['showdate_id = ? AND used = 1',
                                        self.id])
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
    self.thedate.to_formatted_s(:showtime)
  end

  def menu_selection_name ; printable_date ; end

end
