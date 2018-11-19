class Option < ActiveRecord::Base

  attr_encrypted_options.merge!(:key => Figaro.env.attr_encrypted_key!)
  attr_encrypted :stripe_secret
  attr_encrypted :sendgrid_key_value
  attr_encrypted :mailchimp_key

  # support singleton pattern by allowing Option.venue instead of Option.first.venue, its
  @@cached_options = {}
  def self.method_missing(*args)
    opt = args[0].to_s
    if @@cached_options.has_key?(opt)
      @@cached_options[opt]     # note, may be nil!
    else
      @@cached_options[opt] = self.first.send(*args)
    end
  end

  after_save do
    @@cached_options = {}
  end

  validates_numericality_of :advance_sales_cutoff
  validates_inclusion_of :sold_out_threshold, :nearly_sold_out_threshold, :limited_availability_threshold, :in => (1..100), :message => 'must be between 1 and 100 percent'
  validate :availability_levels_monotonically_increase
  validates_inclusion_of :season_start_month, :in => 1..12
  validates_inclusion_of :season_start_day, :in => 1..31
  validates_numericality_of :cancel_grace_period
  validates_presence_of(
    :venue, 
    :precheckout_popup, :terms_of_sale,
    :default_retail_account_code, :default_donation_account_code,
    :default_donation_account_code_with_subscriptions,
    :subscription_order_service_charge_account_code,
    :regular_order_service_charge_account_code,
    :classes_order_service_charge_account_code
    )

  validates_format_of :boxoffice_daemon_notify, :help_email, :with => /@/, :allow_blank => true, :allow_nil => true

  validates_numericality_of :send_birthday_reminders

  validates_numericality_of :subscription_order_service_charge, :greater_than_or_equal_to => 0
  validates_numericality_of :regular_order_service_charge, :greater_than_or_equal_to => 0

  validates_presence_of :subscription_order_service_charge_description,
  :if => Proc.new { |o| o.subscription_order_service_charge > 0 }
  
  validates_presence_of :regular_order_service_charge_description,
  :if => Proc.new { |o| o.regular_order_service_charge > 0 }
  
  validates_presence_of :classes_order_service_charge_description,
  :if => Proc.new { |o| o.classes_order_service_charge > 0 }

  if Rails.env.production?
    validates_format_of :stylesheet_url, :with => Regexp.new('\A/?/stylesheets/default.css\Z|\A\s*https?://')
  end
  
  def availability_levels_monotonically_increase
    errors.add(:nearly_sold_out_threshold, 'must be less than Sold Out threshold') unless sold_out_threshold > nearly_sold_out_threshold
    errors.add(:limited_availability_threshold, 'must be less than Nearly Sold Out threshold') unless nearly_sold_out_threshold > limited_availability_threshold
  end

end
