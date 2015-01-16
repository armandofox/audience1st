# Seed data for Audience1st

class Audience1stSeeder

  def self.seed_all
    self.create_special_customers
    self.create_default_account_code
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
    unless AccountCode.find(:first)
      AccountCode.create!(:name => 'General Fund', :code => '0000', :description => 'General Fund')
    end
  end

  self.seed_all

end

