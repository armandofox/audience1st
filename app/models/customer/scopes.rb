class Customer < ActiveRecord::Base
  default_scope :order => 'last_name, zip'


  named_scope :subscriber_during, lambda { |seasons|
    { :joins => :vouchertypes,
      :conditions => ['vouchertypes.subscription = ? AND vouchertypes.season IN (?)',
        true, seasons] }}


  named_scope :purchased_any_vouchertypes, lambda { |vouchertype_ids|
    { :joins => :vouchertypes,
      :conditions => ['vouchertypes.id IN (?)', vouchertype_ids],
      :select => 'DISTINCT customers.*'}}
  
  def self.purchased_no_vouchertypes(vouchertype_ids)
    Customer.all - Customer.purchased_any_vouchertypes(vouchertype_ids)
  end


  named_scope :seen_any_of, lambda { |show_ids|
    { :joins => [:vouchers,:showdates],
      :conditions => ['items.customer_id = customers.id AND
                      items.showdate_id = showdates.id AND
                      items.type = "Voucher" AND
                      showdates.show_id IN (?)', show_ids],
      :select => 'DISTINCT customers.*'
    }}
  def self.seen_none_of(show_ids) ;  Customer.all - Customer.seen_any_of(show_ids) ;  end

  named_scope :with_open_subscriber_vouchers, lambda { |vtypes|
    { :joins => ',items, showdates',
      :conditions => ['items.customer_id = customers.id AND
                       items.type = "Voucher" AND
                       items.showdate_id = 0 AND
                       items.vouchertype_id IN (?)', vtypes],
      :select => 'DISTINCT customers.*'
    }}


  named_scope :donated_during, lambda { |start_date, end_date, amount|
    { :joins => ',items,orders',
      :select => 'DISTINCT customers.*',
      :conditions => ['items.customer_id = customers.id AND
                       items.amount >= ? AND
                       items.type = "Donation" AND
                       orders.sold_on BETWEEN ? AND ?',
        amount, start_date, end_date] }}
    

end
