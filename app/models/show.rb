class Show < ActiveRecord::Base
  has_many :showdates, :dependent => :destroy
  has_many :future_showdates, :class_name => 'Showdate', :conditions => 'end_advance_sales >= NOW()'
  has_many :vouchers, :through => :showdates
  validates_numericality_of :house_capacity
  validates_presence_of :opening_date, :closing_date
  validates_length_of :name, :within => 3..40, :message => "Show name must be between 3 and 40 characters"

  INFTY = 999999                # UGH!!

  # capacity: if zero, assumes unlimited

  @scaffold_select_order = 'opening_date'
  def scaffold_name
    name + ', opens ' + opening_date.to_s
  end

  def revenue
    self.vouchers.inject(0) {|r,v| r + v.price}
  end

  def revenue_by_type(vouchertype_id)
    self.vouchers.find_by_id(vouchertype_id).inject(0) {|sum,v| sum + v.price}
  end

  def capacity
    self.showdates.inject(0) { |cap,sd| cap + sd.capacity }
  end

  def percent_sold
    showdates.size.zero? ? 0.0 :
      showdates.inject(0) { |t,sd| t + sd.percent_sold }.to_f / showdates.size
  end

  def name_with_run_dates
    "#{name} - #{opening_date.to_formatted_s(:month_day_only)}-#{closing_date.to_formatted_s(:month_day_only)}"
  end
end
