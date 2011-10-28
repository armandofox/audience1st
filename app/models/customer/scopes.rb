class Customer < ActiveRecord::Base
  default_scope :order => 'last_name, zip'
  named_scope :subscriber_during, lambda { |seasons|
    { :joins => :vouchertypes,
      :conditions => ['vouchertypes.subscription = ? AND vouchertypes.season IN (?)',
        true, seasons] }
  }
  named_scope :purchased_any_vouchertypes, lambda { |vouchertype_ids|
    { :joins => :vouchertypes,
      :conditions => ['vouchertypes.id IN (?)', vouchertype_ids] }
  }
  def self.purchased_no_vouchertypes(vouchertype_ids)
    Customer.all - Customer.purchased_any_vouchertypes(vouchertype_ids)
  end
  named_scope :seen_any_shows, lambda { |show_ids|
    { :joins => ',items, showdates',
      :conditions => ['items.customer_id = customers.id AND
                      items.showdate_id = showdates.id AND
                      showdates.show_id IN (?)', show_ids],
      :select => 'DISTINCT customers.*'
    }
  }
  def self.seen_no_shows(show_ids)
    Customer.all - Customer.seen_any_shows(show_ids)
  end
end
