module StagingHelper
  TENANT = 'sandbox'
  def abort_if_production!
    abort "Must set CLOBBER_PRODUCTION=1 to do this on production DB" if
      Rails.env.production? && ENV['CLOBBER_PRODUCTION'].blank?
  end
  def switch_to_staging!
    abort_if_production!
    Apartment::Tenant.switch! StagingHelper::TENANT
  end
end

namespace :staging do

  tenant = 'sandbox'

  desc "Reset fake data in staging database (tenant '#{tenant}')"
  task :reset => :environment do
    StagingHelper.abort_if_production!
    Apartment::Tenant.drop(StagingHelper::TENANT) rescue nil
    Apartment::Tenant.create StagingHelper::TENANT
    StagingHelper.switch_to_staging!
    load File.join(Rails.root, 'db', 'seeds.rb')
  end
  desc "Populate database tenant '#{StagingHelper::TENANT}' with NUM_CUSTOMERS fake customers (default 100) all with password 'pass', plus an admin whose login/pass is admin@audience1st.com/admin."
  task :fake_customers => :environment do
    StagingHelper.switch_to_staging!
    num_customers = (ENV['NUM_CUSTOMERS'] || '100').to_i
    1.upto num_customers  do
      FactoryBot::create(:customer,
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :email => Faker::Internet.unique.safe_email,
        :password => 'pass',
        :street => Faker::Address.street_address,
        :city => Faker::Address.city,
        :state => 'CA', :zip => sprintf("94%03d", rand(999)))
    end
  end

  desc "Populate tenant '#{tenant}' with a fake show opening on DATE (default: 1 week from now) with NUM_SHOWDATES performances (default 3) each having house capacity CAPACITY (default 50)"
  task :fake_show => :environment do
    Apartment::Tenant.switch! tenant
    date = Time.parse(ENV['DATE']) rescue 1.week.from_now.change(:hour => 20)
    num_showdates = (ENV['NUM_SHOWDATES'] || '3').to_i
    cap =           (ENV['CAPACITY']      || '50').to_i
    show = FactoryBot::create(:show, :name => Faker::Show.play, :house_capacity => cap)
    for i in 1..num_showdates do
      FactoryBot::create(:showdate, :show => show, :thedate => date + i.days)
    end
  end

  namespace :sell do

    desc "In tenant '#{tenant}', delete all sales data (vouchertypes, valid-vouchers, orders) but keep customers"
    task :reset => :environment do
      Apartment::Tenant.switch! tenant
      ValidVoucher.delete_all
      Vouchertype.delete_all
      Item.delete_all
      Order.delete_all
    end

    desc "In tenant '#{tenant}', create 2 price points 'General' and 'Student/TBA', and sell every showdate to PERCENT capacity (default 50)"
    task :revenue => :environment do
      Apartment::Tenant.switch! tenant
      percent = (ENV['PERCENT'] || '50').to_i / 100.0
      price1 = FactoryBot::create(:revenue_vouchertype, :name => 'General', :price => 35, :walkup_sale_allowed => true) if Vouchertype.where(:name => 'General').empty?
      price2 = FactoryBot::create(:revenue_vouchertype, :name => 'Student/TBA', :price => 25, :walkup_sale_allowed => true) if Vouchertype.where(:name => 'Student/TBA').empty?
      num_customers = Customer.count
      Showdate.all.each do |perf|
        v1 = FactoryBot::create(:valid_voucher, :vouchertype => price1, :showdate => perf)
        v2 = FactoryBot::create(:valid_voucher, :vouchertype => price2, :showdate => perf)
        # sell percentage of tickets
        while perf.compute_total_sales < (percent * perf.house_capacity) do
          # pick a customer
          customer = Customer.offset(rand num_customers).first
          # pick a number of tickets, 1-4, skewed towards 1 and 2
          num_tix = [1,1,2,2,2,2,3,4,4].sample
          # pick which price point they'll use
          valid_voucher = [v1,v2].sample
          # buy it
          o = Order.new(:purchaser => customer, :processed_by => customer, :customer => customer, :purchasemethod => Purchasemethod.get_type_by_name('box_cash'))
          o.add_tickets(valid_voucher, num_tix)
          begin
            o.finalize!
          rescue RuntimeError => e
            "Order errors: #{o.errors.full_messages}"
          end
        end
      end
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
