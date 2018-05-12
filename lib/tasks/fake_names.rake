namespace :db do
  desc "Populate database tenant TENANT (default: 'staging'; or no tenant if multitenancy is turned off) with NUM_CUSTOMERS fake customers (default 500), including an admin whose login is admin@audience1st.com/admin."
  task :fake_customers => :environment do
    tenant = ENV['TENANT'] || 'staging'
    num_customers = (ENV['NUM_CUSTOMERS'] || '500').to_i
    Apartment::Tenant.drop(tenant) rescue nil
    Apartment::Tenant.create tenant 
    Apartment::Tenant.switch! tenant
    load File.join(Rails.root, 'db', 'seeds.rb')
    1.upto num_customers  do
      FactoryBot::create(:customer,
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :email => Faker::Internet.unique.safe_email,
        :street => Faker::Address.street_address,
        :city => Faker::Address.city,
        :state => 'CA', :zip => sprintf("94%03d", rand(999)))
    end
  end
  desc "Given ENV[FILE] is a CSV with columns <last, first, street, phone, email>, repopulates development DB with fake data, skipping any superadmins."
  task :fake_names => :environment do
    abort "Only works for RAILS_ENV=development" unless Rails.env.development?
    require 'string_extras'
    require 'generator'
    require 'csv'
    csv = CSV::Reader.create(File.open(ENV['FILE'], 'r'))
    custs = Customer.find(:all)
    SyncEnumerator.new(custs, csv).each do |customer,row|
      break unless customer
      unless customer.role == 100 # skip admins
        customer.update_attribute(:last_name, row[0].data)
        customer.update_attribute(:first_name, row[1].data)
        customer.update_attribute(:street, row[2].data) unless
          customer.street.blank?
        customer.update_attribute(:day_phone,row[3].data) unless
          customer.day_phone.blank?
        customer.update_attribute(:eve_phone, '')
        unless customer.email.blank?
          customer.update_attribute(:email, row[4].data)
        end
      end
    end
  end

  desc "Given ENV[FILE] is a CSV with columns <last, first, street, phone, email>, creates ENV[NUM] fake customers in the database, all with password 'pass'"
  task :populate_fake_names => :environment do
    require 'string_extras'
    require 'generator'
    require 'csv'
    i = ENV['NUM'].to_i
    CSV::Reader.parse(File.open(ENV['FILE'], 'r')) do |row|
      Customer.create!(:last_name => row[0].data,
        :first_name => row[1].data,
        :street => row[2].data,
        :city => 'Berkeley',
        :state => 'CA',
        :zip => '94720',
        :day_phone => row[3].data,
        :password => 'pass',
        :email => row[4].data)
      i -= 1
      break if i.zero?
    end
  end

end
