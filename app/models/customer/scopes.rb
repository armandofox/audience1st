class Customer < ActiveRecord::Base
  default_scope {  distinct.order([:last_name, :zip]) }

  scope :regular_customers, ->()  { where('role >= 0') }
  
  scope :subscriber_during, ->(seasons) {
    joins(:vouchertypes).
    where('vouchertypes.subscription = ? AND vouchertypes.season IN (?)', true, seasons)
  }

  scope :nonsubscriber_during, ->(seasons) {
    has_subscription_vouchers = Voucher.
    joins(:vouchertype).
    where('items.customer_id = customers.id').
    where('vouchertypes.subscription = ? AND vouchertypes.season IN (?)', true, seasons)
    # use NOT EXISTS to invert the above join:
    where("NOT EXISTS(#{has_subscription_vouchers.to_sql})")
  }
  
  scope :purchased_any_vouchertypes, ->(vouchertype_ids) {
    joins(:vouchers).
    where('items.vouchertype_id' => vouchertype_ids).
    where('items.finalized' => true)
  }
  
  scope :purchased_no_vouchertypes, ->(vouchertype_ids) {
    matching_vouchers = Voucher.where('items.customer_id = customers.id').
    where('items.vouchertype_id' => vouchertype_ids, 'items.finalized' => true)
    where("NOT EXISTS(#{matching_vouchers.to_sql})")
  }

  # def self.purchased_no_vouchertypes(vouchertype_ids)
  #   Customer.all - Customer.purchased_any_vouchertypes(vouchertype_ids)
  # end

  scope :seen_any_of, ->(show_ids) {
    joins(:vouchers, :showdates).
    where('items.customer_id = customers.id').
    where('items.showdate_id = showdates.id').
    where('items.finalized' => true,
      'items.type' => 'Voucher',
      'showdates.show_id' => show_ids)
  }
  
  def self.seen_none_of(show_ids)
    not_seen_these_shows = Customer.
      includes(:vouchers, :showdates).
      where.not(:showdates => {:show_id => show_ids})
    not_seen_any_shows = Customer.
      includes(:vouchers, :showdates).
      where(:items => {:customer_id => nil})
    not_seen_these_shows.or(not_seen_any_shows).distinct
  end

  scope :with_open_subscriber_vouchers, ->(vtypes) {
    joins(:items).
    where('items.customer_id = customers.id').
    where('items.type' => 'Voucher', 'items.vouchertype_id' => vtypes).
    where('items.showdate_id = 0 OR items.showdate_id IS NULL')
  }

  scope :donated_during, ->(start_date, end_date, amount) {
    joins(:items, :orders).
    where('items.finalized' => true).
    where(%q{items.customer_id = customers.id AND items.amount >= ? AND items.type = 'Donation'
            AND orders.sold_on BETWEEN ? AND ?},
      amount, start_date, end_date)
  }

end
