# Seed data for Audience1st
require 'faker'

class Audience1stSeeder

  def self.seed_all
    self.create_options
    self.create_special_customers
    self.create_default_account_code
    self.create_purchasemethods
    if Rails.env == 'development'
      self.create_fake_customers
    end
  end
  # Options
  # Basic options for running features and specs


  #  Special customers that must exist and cannot be deleted

  require 'customer'
  @@special_customers = {
    :walkup => {
      :role => Customer::ROLES[:walkup],
      :first_name => 'WALKUP',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true
    },
    :generic => {
      :role => Customer::ROLES[:generic],
      :first_name => 'GENERIC',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true,
    },
    :boxoffice_daemon => {
      :role => Customer::ROLES[:boxoffice_daemon],
      :first_name => 'BoxOffice',
      :last_name => 'Daemon',
      :blacklist => true,
      :e_blacklist => true
    },
    :anonymous => {
      :role => Customer::ROLES[:anonymous],
      :first_name => 'ANONYMOUS',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true
    }
  }
  def self.create_fake_customers
    (1..1000).each do |n|
      customer = Customer.new(
          :first_name => Faker::Name.first_name,
          :last_name=> Faker::Name.last_name,
          :password=>'123',
          :email => Faker::Internet.email,
          :city => Faker::Address.city,
          :state => Faker::Address.state,
          :street => Faker::Address.street_address,
          :zip => Faker::Address.zip_code)
      customer.created_by_admin = true
      customer.save!
    end
  end

  def self.create_special_customers
    Rails.logger.info "Creating special customers"
    # Create Admin (God) login
    unless Customer.find_by_role(100)
      admin = Customer.new(:first_name => 'Super',
        :last_name => 'Administrator',
        :password => 'admin',
        :email => 'admin@audience1st.com')
      admin.created_by_admin = true
      admin.role = 100
      admin.save!
      identity = Authorization.new(:customer => admin, :provider => "identity", :uid => 'admin@audience1st.com', :password_digest => "$2a$10$AslSVKilS.kOSgil9exo7O.pEv1W88BMz.EToN4W81aECT7oLuNo2")
      identity.password = "admin"
      identity.save!
    end
    @@special_customers.each_pair do |which, attrs|
      unless Customer.find_by_first_name(attrs[:first_name])
        c = Customer.new(attrs.except(:role))
        c.role = attrs[:role]
        c.created_by_admin = true
        c.save!
      end
    end
  end
  
  def self.create_default_account_code
    Rails.logger.info "Creating default account code"
    a = AccountCode.first ||
      AccountCode.create!(:name => 'General Fund', :code => '0000', :description => 'General Fund')
    id = a.id
    # set it as default account code for various things
    Option.first.update_attributes!(
      :default_donation_account_code => a.id,
      :default_donation_account_code_with_subscriptions => a.id,
      :default_retail_account_code => a.id,
      :subscription_order_service_charge_account_code => a.id,
      :regular_order_service_charge_account_code => a.id,
      :classes_order_service_charge_account_code => a.id)
  end

  def self.create_purchasemethods
    Rails.logger.info "Creating purchasemethods"
    ["Web - Credit Card","web_cc",false,
      "No payment required","none",true,
      "Box office - Credit Card","box_cc",false,
      "Box office - Cash","box_cash",false,
      "Box office - Check","box_chk",false,
      "Payment Due","pmt_due",false,
      "External Vendor","ext",false,
      "Part of a package","bundle",true,
      "Other","?purch?",false,
      "In-Kind Goods or Services","in_kind",true].each_slice(3) do |pm|
      Purchasemethod.create!(:description => pm[0],
        :shortdesc => pm[1], :nonrevenue => pm[2])
    end
  end

  def self.create_options
    Rails.logger.info "Creating default options"
    option = Option.new(
      :venue => 'Test Theater',
      :advance_sales_cutoff => 60,
      :sold_out_threshold => 90,
      :nearly_sold_out_threshold => 80,
      :allow_gift_tickets => false,
      :allow_gift_subscriptions => false,
      :season_start_month => 1,
      :season_start_day => 1,
      :cancel_grace_period => 1440,
      :send_birthday_reminders => 0,
      :terms_of_sale => 'Sales Final',
      :precheckout_popup => 'Please double check dates',
      :venue_homepage_url => 'http => //test.org',
      :default_retail_account_code =>  9999,
      :default_donation_account_code => 9999,
      :default_donation_account_code_with_subscriptions => 9999
      )
    option.venue_id = 111
    option.venue_shortname = 'testing'
    option.save!
  end 
  self.seed_all
end

