# Seed data for Audience1st

class Audience1stSeeder

  def self.seed_all
    self.create_special_customers
    self.create_default_account_code
    self.create_purchasemethods
  end

  #  Special customers that must exist and cannot be deleted

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

  def self.create_special_customers
    # Create Admin (God) login
    unless Customer.find_by_role(100)
      admin = Customer.new(:first_name => 'Super',
        :last_name => 'Administrator',
        :password => 'admin',
        :email => 'admin@audience1st.com')
      admin.created_by_admin = true
      admin.role = 100
      admin.save!
    end
    @@special_customers.each_pair do |which, attrs|
      unless Customer.find_by_role(attrs[:role])
        c = Customer.new(attrs)
        c.role = attrs[:role]
        c.created_by_admin = true
        c.save!
      end
    end
  end
    
  def self.create_default_account_code
    a = AccountCode.find(:first) ||
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

  self.seed_all

end

