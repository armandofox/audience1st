class Option < ActiveRecord::Base

  attr_protected :venue_id, :venue_shortname

  # support singleton pattern by allowing Option.venue instead of Option.first.venue, its
  def self.method_missing(*args)
    self.first.send(*args)
  end
  
  validates_numericality_of :advance_sales_cutoff
  validates_inclusion_of :sold_out_threshold, :nearly_sold_out_threshold, :in => (1..100), :message => 'must be between 1 and 100 percent'
  validates_inclusion_of :season_start_month, :in => 1..12
  validates_inclusion_of :season_start_day, :in => 1..31
  validates_numericality_of :cancel_grace_period
  validates_presence_of(
    :venue, :venue_address, :venue_city_state_zip, :venue_telephone, :venue_homepage_url,
    :boxoffice_telephone, :precheckout_popup, :terms_of_sale, :privacy_policy_url,
    :default_retail_account_code, :default_donation_account_code,
    :default_donation_account_code_with_subscriptions,
    :subscription_order_service_charge_account_code,
    :regular_order_service_charge_account_code,
    :classes_order_service_charge_account_code
    )

  validates_numericality_of :send_birthday_reminders

  validates_numericality_of :subscription_order_service_charge, :greater_than_or_equal_to => 0
  validates_numericality_of :regular_order_service_charge, :greater_than_or_equal_to => 0

  validates_presence_of :subscription_order_service_charge_description,
  :if => Proc.new { |o| o.subscription_order_service_charge > 0 }
  
  validates_presence_of :regular_order_service_charge_description,
  :if => Proc.new { |o| o.regular_order_service_charge > 0 }
  
  validates_presence_of :classes_order_service_charge_description,
  :if => Proc.new { |o| o.classes_order_service_charge > 0 }
  
end
