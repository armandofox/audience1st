class Showdate < ActiveRecord::Base

  # for reservation list

  def grouped_vouchers
    perf_vouchers = self.advance_sales_vouchers.includes(:customer)
    total = perf_vouchers.size
    vouchers = perf_vouchers.group_by do |v|
      "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
    end
    return [total,vouchers]
  end

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
    [self.house_capacity - total_sales.size, 0].max
  end

  def saleable_seats_left
    [self.max_advance_sales - total_sales.size, 0].max
  end

  def really_sold_out? ; saleable_seats_left < 1 ; end

  # percent of max sales: may exceed 100
  def percent_sold
    max_advance_sales.zero? ? 100 : (100.0 * total_sales.size/max_advance_sales).floor
  end

  # percent of house: may exceed 100
  def percent_of_house
    house_capacity.zero? ? 100 : (100.0 * total_sales.size / house_capacity).floor
  end

  def sold_out? ; really_sold_out? || percent_sold.to_i >= Option.sold_out_threshold ; end

  def nearly_sold_out? ; !sold_out? && percent_sold.to_i >= Option.nearly_sold_out_threshold ; end

  def total_sales
    vouchers.finalized
  end

  def advance_sales_vouchers
    finalized_vouchers.advance_sales
  end
  def walkup_sales_vouchers
    finalized_vouchers.walkup_sales
  end

  def num_checked_in
    finalized_vouchers.checked_in.count
  end
  def num_waiting_for
    [0, advance_sales_vouchers.size - num_checked_in].max
  end

  

end
