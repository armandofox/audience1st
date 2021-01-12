class Option < ActiveRecord::Base

  attr_encrypted_options.merge!(:key => Figaro.env.attr_encrypted_key!)
  attr_encrypted :stripe_secret
  attr_encrypted :mailchimp_key

  serialize :feature_flags, Array

  def self.method_missing(*args)
    Option.first.send(*args)
  end

  # Feature flags
  def self.feature_enabled?(str)
    Option.first.feature_flags.include?(str)
  end
  def self.enable_feature!(str)
    Option.first.update_attributes!(:feature_flags => Option.feature_flags | [str])
  end
  def self.disable_feature!(str)
    Option.first.update_attributes!(:feature_flags => Option.feature_flags - [str])
  end

  validates_format_of :restrict_customer_email_to_domain, :with => /\A[^-_][-_.A-Za-z0-9]*[^-_]\z/, :allow_blank => true

  validates_numericality_of :advance_sales_cutoff
  validates_numericality_of :order_timeout, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 15
  validates_inclusion_of :nearly_sold_out_threshold, :limited_availability_threshold, :in => (1..100), :message => 'must be between 1 and 100 percent'
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

  validates_format_of :box_office_email,
                      :with => URI::MailTo::EMAIL_REGEXP, :allow_blank => false,
                      :allow_nil => false, :message => 'must be a valid email address'
  validates_format_of :help_email,
                      :with => URI::MailTo::EMAIL_REGEXP, :allow_blank => false,
                      :allow_nil => false, :message => 'must be a valid email address'

  validates_numericality_of :send_birthday_reminders

  validates_numericality_of :subscription_order_service_charge, :greater_than_or_equal_to => 0
  validates_numericality_of :regular_order_service_charge, :greater_than_or_equal_to => 0

  validates_presence_of :subscription_order_service_charge_description,
  :if => Proc.new { |o| o.subscription_order_service_charge > 0 }
  
  validates_presence_of :regular_order_service_charge_description,
  :if => Proc.new { |o| o.regular_order_service_charge > 0 }
  
  validates_presence_of :classes_order_service_charge_description,
  :if => Proc.new { |o| o.classes_order_service_charge > 0 }

  validates_presence_of :html_email_template
  validate :html_email_template_checks

  validates_format_of :stylesheet_url, :if => Proc.new { Rails.env.production? }, :allow_blank => true, :with => URI.regexp(['https']), :message => 'must be a valid URI beginning with "https://"'
  
  def availability_levels_monotonically_increase
    errors.add(:limited_availability_threshold, 'must be less than Nearly Sold Out threshold') unless nearly_sold_out_threshold > limited_availability_threshold
  end

  def html_email_template_checks
    errors.add(:html_email_template, "must begin with a <!DOCTYPE html> declaration") unless
      html_email_template =~ /\A<!doctype\s+html>/i
    errors.add(:html_email_template, "must contain exactly one occurrence of the placeholder '#{Mailer::BODY_TAG}' for the email message body") unless
      html_email_template.scan(Mailer::BODY_TAG).size == 1
    errors.add(:html_email_template, "cannot contain more than one occurrence of '#{Mailer::FOOTER_TAG}'") if
      html_email_template.scan(Mailer::FOOTER_TAG).size > 1
  end

  # utility methods on specific options

  def self.humanize_season(year=Time.this_season)
    Option.first.season_start_month >= 6  ?
      "#{year.to_i}-#{year.to_i + 1}" :
      year.to_s
  end
  
end
