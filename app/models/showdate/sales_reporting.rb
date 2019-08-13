class Showdate < ActiveRecord::Base

  # reporting

  def sales_by_type(vouchertype_id)
    return self.vouchers.where('vouchertype_id = ?', vouchertype_id).count
  end

  def revenue
    self.vouchers.inject(0) {|sum,v| sum + v.amount.to_f}
  end

  def revenue_per_seat
    all_vouchers = self.vouchers.joins(:vouchertype).
      where(:vouchertypes => {:category => ['comp', 'revenue']})
    total_seated = comp_seats + nonsubscriber_revenue_seats
    if (revenue.zero? || total_seated.zero?) then 0.0 else revenue/total_seated end
  end

  private
  
  def comp_seats
    self.vouchers.comp.count
  end

  def nonsubscriber_revenue_seats
    self.vouchers.revenue.count
  end

  public
  
  def total_offered_for_sale ; house_capacity ; end

  def percent_max_advance_sales
    house_capacity.zero? ? 100.0 : 100.0 * max_advance_sales / house_capacity
  end

  def total_seats_left
    [self.house_capacity - compute_total_sales, 0].max
  end

  def saleable_seats_left
    [self.max_advance_sales - compute_total_sales, 0].max
  end

  def really_sold_out? ; saleable_seats_left < 1 ; end

  # percent of max sales: may exceed 100
  def percent_sold
    max_advance_sales.zero? ? 100 : (100.0 * compute_total_sales/max_advance_sales).floor
  end

  # percent of house: may exceed 100
  def percent_of_house
    house_capacity.zero? ? 100 : (100.0 * compute_total_sales / house_capacity).floor
  end

  def sold_out? ; really_sold_out? || percent_sold.to_i >= Option.sold_out_threshold ; end

  def nearly_sold_out? ; !sold_out? && percent_sold.to_i >= Option.nearly_sold_out_threshold ; end

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

  

end
