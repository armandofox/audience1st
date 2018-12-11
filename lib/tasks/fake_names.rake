#  In general, to reconstitute the fake database, run tasks in this order:
#    TENANT=a1-staging rake client:provision  (if a1-staging database/schema not set up)
#    rake staging:reset 
#    rake staging:fake_customers         - creates customers
#    rake staging:fake_season            - creates shows & showdates
#    rake staging:fake_vouchers          - creates & makes 2 kinds of valid revenue tix for shows
#    rake staging:fake_subscriptions     - creates a subscription voucher w/1 tx per show


module StagingHelper
  TENANT = 'a1-staging'
  SHOWS = ['Company', 'Fiddler on the Roof', 'West Side Story']
  CITIES = ['Oakland', 'San Francisco', 'Alameda', 'Hayward', 'San Leandro', 'Berkeley',
    'Daly City', 'Castro Valley', 'Pleasanton', 'Walnut Creek', 'Concord', 'Antioch', 'Pittsburg',
    'Union City', 'Fremont', 'Albany', 'El Cerrito', 'Dublin', 'Livermore', 'Newark']
  def self.abort_if_production!
    abort "Must set CLOBBER_PRODUCTION=1 to do this on production DB" if
      Rails.env.production? && ENV['CLOBBER_PRODUCTION'].blank?
  end
  def self.switch_to_staging!
    abort_if_production!
    Apartment::Tenant.switch! StagingHelper::TENANT
  end
end

staging = namespace :staging do
 
  desc "Re-create fake data in staging database (tenant '#{StagingHelper::TENANT}')"
  task :reload => :environment do
    staging['reset'].invoke     # truncate & re-seed DB
    staging['fake_customers'].invoke # create fake customers
    staging['fake_season'].invoke    # create 3 shows with 3 weekend runs each
    staging['fake_vouchers'].invoke  # create 2 revenue vouchertypes, make valid for all showdates
    staging['fake_subscriptions'].invoke # create a sub with 1tx per show
  end

  desc "Reset fake data in staging database (tenant '#{StagingHelper::TENANT}')"
  task :reset => :environment do
    StagingHelper.abort_if_production!
    Apartment::Tenant.drop(StagingHelper::TENANT) rescue nil
    Apartment::Tenant.create StagingHelper::TENANT
    StagingHelper.switch_to_staging!
    load File.join(Rails.root, 'db', 'seeds.rb')
    Option.first.update_attributes!(
      :venue => 'A1 Staging Theater',
      :season_start_month => (1.month.ago).month)
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
        :city => StagingHelper::CITIES.sample,
        :state => 'CA', :zip => sprintf("94%03d", rand(999)))
    end
  end

  desc "Create 3 fake productions, each with 3-weekend (Fri/Sat/Sun) run, with first show opening on the first Friday of next month, each show's tickets going on sale 2 weeks before opening, two price points for each production, and a Subscription that includes all three."
  task :fake_season => :environment do
    StagingHelper::switch_to_staging!
    range_start = Time.now.at_beginning_of_month + 1.month
    StagingHelper::SHOWS.each_with_index do |show,index|
      # every Fri, Sat, Sun at 8pm
      showdates = DatetimeRange.new(
        :start_date => range_start, :end_date => range_start + 25.days,
        :hour => 20, :days => [5,6,0]).
        dates
      show = FactoryBot::create(:show,
        :name => show,
        :house_capacity => 50,
        :opening_date => showdates.first,
        :closing_date => showdates.last,
        :listing_date => Time.current)
      showdates.each do |date|
        showdate = FactoryBot::create(:showdate,
          :show => show,
          :thedate => date,
          :end_advance_sales => date - 3.hours)
      end
      range_start += 1.month
    end
  end

  desc "Create two price points (General - $35 and Student/TBA - $30) and make those vouchertypes valid for all performances"
  task :fake_vouchers => :environment do
    StagingHelper::switch_to_staging!
    price1 = FactoryBot::create(:revenue_vouchertype, :name => 'General', :price => 35, :walkup_sale_allowed => true) if Vouchertype.where(:name => 'General').empty?
    price2 = FactoryBot::create(:revenue_vouchertype, :name => 'Student/TBA', :price => 25, :walkup_sale_allowed => true) if Vouchertype.where(:name => 'Student/TBA').empty?
    Showdate.all.each do |perf|
      FactoryBot::create(:valid_voucher, :vouchertype => price1, :showdate => perf,
        :end_sales => perf.thedate - 1.hour)
      FactoryBot::create(:valid_voucher, :vouchertype => price2, :showdate => perf,
        :end_sales => perf.thedate - 1.hour)
    end
  end
  
  desc "Create a subscription that includes 1 ticket to each of the season's fake shows (run the fake_season task first)"
  task :fake_subscriptions => :environment do
    StagingHelper::switch_to_staging!
    now = Time.current.change(:minute => 0)
    sub_vouchers = StagingHelper::SHOWS.map do |show|
      sub_voucher = FactoryBot::create(:vouchertype_included_in_bundle,
        :name => "#{show} (subscriber)")
      # make it valid for all perfs of that show
      Show.find_by(:name => show).showdates.each do |date|
        FactoryBot::create(:valid_voucher, :vouchertype => sub_voucher, :showdate => date,
          :start_sales => now, :end_sales => date.thedate - 1.hour)
      end
      sub_voucher
    end
    sub = FactoryBot::create(:bundle,
      :subscription => true,
      :name => 'Season Subscription',
      :including => Hash[sub_vouchers.zip(Array.new(sub_vouchers.size) { 1 })])
    FactoryBot::create(:valid_voucher, :vouchertype => sub,
      :start_sales => now, :end_sales => 6.months.from_now)
  end
  
  namespace :sell do

    desc "In tenant '#{StagingHelper::TENANT}', delete all sales data (vouchertypes, valid-vouchers, orders) but keep customers, shows, and show dates"
    task :reset => :environment do
      StagingHelper::switch_to_staging!
      Item.delete_all
      Order.delete_all
      Txn.delete_all
    end

    desc "Sell 1,2, or 3 subscriptions to PERCENT of all customers (default 50) so that average # of subs per customer is 2, and reserve sub vouchers for randomly chosen showdates"
    task :subscribers => :environment do
      StagingHelper::switch_to_staging!
      percent = (ENV['PERCENT'] || '50').to_i / 100.0
      sub_voucher = ValidVoucher.includes(:vouchertype).
        where(:vouchertypes => {:category => :bundle, :subscription => true}).
        first
      customers = Customer.where('role >= 0 AND role<100') # hack: exclude special customers & admin
      customers = customers.sample(customers.size * percent * 0.5) # since will sell avg of 2 per pax
      customers.each do |customer|
        o = Order.new(:purchaser => customer, :processed_by => customer, :customer => customer,
          :purchasemethod => Purchasemethod.get_type_by_name('box_chk'))
        num_tix = [1,2,2,2,2,3,4].sample
        o.add_tickets(sub_voucher, num_tix)
        o.finalize!
        # now reserve each of those vouchers for a random perf of each show
        # TBD
      end
    end
    
    desc "For each showdate, sell PERCENT of remaining seats (default 50) using a random mix of revenue vouchertypes for that showdate"
    task :revenue => :environment do
      StagingHelper::switch_to_staging!
      percent = (ENV['PERCENT'] || '50').to_i / 100.0
      customers = Customer.where('role >= 0 AND role<100') # hack: exclude special customers & admin
      Showdate.all.each do |perf|
        valid_vouchers = ValidVoucher.includes(:vouchertype).where(:showdate => perf, :vouchertypes => {:category => :revenue})
        # sell percentage of tickets
        while perf.compute_total_sales < (percent * perf.house_capacity) do
          # pick a customer
          customer = customers.sample
          # pick a number of tickets, 1-4, skewed towards 1 and 2
          num_tix = [1,1,2,2,2,2,3,4,4].sample
          # pick which price point they'll use
          valid_voucher = valid_vouchers.sample
          # buy it
          o = Order.new(:purchaser => customer, :processed_by => customer, :customer => customer, :purchasemethod => Purchasemethod.get_type_by_name('box_cash'))
          o.add_tickets(valid_voucher, num_tix)
          begin
            o.finalize!
          rescue RuntimeError,Order::NotReadyError => e
            1 if byebug
            "Order errors: #{o.errors.full_messages}"
          end
        end
      end
    end

  end
end
