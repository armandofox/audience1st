#  In general, to reconstitute the fake database, run tasks in this order:
#    TENANT=a1-staging rake client:provision  (if a1-staging database/schema not set up)
#    rake staging:reset 
#    rake staging:fake_customers         - creates customers
#    rake staging:fake_season            - creates shows & showdates
#    rake staging:fake_vouchers          - creates & makes 2 kinds of valid revenue tix for shows
#    rake staging:fake_subscriptions     - creates a subscription voucher w/1 tx per show

require 'csv'

module StagingHelper
  TENANT = ENV['TENANT'] || 'a1-staging'
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
  def self.dot
    print "."; $stdout.flush
  end
end

staging = namespace :staging do
  
  desc "Re-create fake data in staging database (tenant '#{StagingHelper::TENANT}')"
  task :initialize => :environment do
    puts "Clearing out old staging data..."
    staging['reset'].invoke     # truncate & re-seed DB
    staging['api_keys'].invoke  # set correct API keys for staging/test mode
    print "\nCreating customers"
    staging['fake_customers'].invoke # create fake customers
    print "\nCreating productions and vouchers..."
    staging['fake_season'].invoke    # create 3 shows with 3 weekend runs each
    staging['fake_vouchers'].invoke  # create 2 revenue vouchertypes, make valid for all showdates
    staging['fake_subscriptions'].invoke # create a sub with 1tx per show
    staging['reset_sales'].invoke
    print "\n'Selling' revenue tickets"
    staging['sell_revenue'].invoke
    print "\n'Selling' subscriptions..."
    staging['sell_subscriptions'].invoke
    print "\nRecording donations"
    staging['fake_donations'].invoke
    puts "\nStaging data is ready"
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

  desc "Set staging API keys STRIPE_SECRET, STRIPE_KEY from Figaro"
  task :api_keys => :environment do
    StagingHelper::switch_to_staging!
    Option.first.update_attributes!(
      :stripe_key => Figaro.env.STRIPE_KEY!,
      :stripe_secret => Figaro.env.STRIPE_SECRET!,
      :sendgrid_domain => '')   # domain blank disables email sending
  end

  desc "Populate database tenant '#{StagingHelper::TENANT}' with NUM_CUSTOMERS fake customers (default 100) all with password 'pass', plus an admin whose login/pass is admin@audience1st.com/admin."
  task :fake_customers => :environment do
    StagingHelper.switch_to_staging!
    num_customers = (ENV['NUM_CUSTOMERS'] || '100').to_i
    now = Time.current.at_beginning_of_day
    (CSV.read(File.join(Rails.root, 'spec', 'fake_names.csv')))[0,num_customers].each do |c|
      cust = Customer.new(
        :last_name => c[0], :first_name => c[1], :street => c[2], :day_phone => c[3], :email => c[4],
        :password => 'pass',
        :city => StagingHelper::CITIES.sample,
        :state => 'CA', :zip => sprintf("94%03d", rand(999))
        )
      cust.last_login = now
      cust.save!
      StagingHelper::dot
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
      show = Show.create!(
        :name => show,
        :house_capacity => 50,
        :opening_date => showdates.first,
        :closing_date => showdates.last,
        :listing_date => Time.current)
      showdates.each do |date|
        showdate = show.showdates.create!(
          :max_advance_sales => show.house_capacity,
          :thedate => date,
          :end_advance_sales => date - 3.hours)
      end
      range_start += 1.month
    end
  end

  desc "Create two price points (General - $35 and Student/TBA - $30) and make those vouchertypes valid for all performances"
  task :fake_vouchers => :environment do
    StagingHelper::switch_to_staging!
    vtype_opts = {
      :account_code => AccountCode.default_account_code,
      :category => :revenue,
      :walkup_sale_allowed => true,
      :offer_public => Vouchertype::ANYONE,
      :season => Time.this_season}
    price1 = Vouchertype.create!({:name => 'General', :price => 35}.merge(vtype_opts)) if Vouchertype.where(:name => 'General').empty?
    price2 = Vouchertype.create!({:name => 'Student/TBA', :price => 25}.merge(vtype_opts)) if Vouchertype.where(:name => 'Student/TBA').empty?
    now = Time.current.at_beginning_of_day
    Showdate.all.each do |perf|
      perf.valid_vouchers.create!(:vouchertype => price1, :start_sales => now, :end_sales => perf.thedate - 1.hour)
      perf.valid_vouchers.create!(:vouchertype => price2, :start_sales => now, :end_sales => perf.thedate - 1.hour)
    end
  end
  
  desc "Create a subscription that includes 1 ticket to each of the season's fake shows (run the fake_season task first)"
  task :fake_subscriptions => :environment do
    StagingHelper::switch_to_staging!
    now = Time.current.at_beginning_of_day
    sub_vouchers = StagingHelper::SHOWS.map do |show|
      sub_voucher = Vouchertype.create!(
        :category => :subscriber,
        :account_code => AccountCode.default_account_code,
        :season => Time.this_season,
        :name => "#{show} (subscriber)")
      # make it valid for all perfs of that show
      Show.find_by(:name => show).showdates.each do |date|
        date.valid_vouchers.create!(:vouchertype => sub_voucher, 
          :start_sales => now, :end_sales => date.thedate - 1.hour)
      end
      sub_voucher
    end
      :category => :bundle,
      :subscription => true,
      :price => 70.00,
      :name => 'Season Subscription 1',
      :name => 'Season Subscription',
      :season => Time.this_season,
      :offer_public => Vouchertype::ANYONE,
      :included_vouchers => sub_vouchers.map(&:id).map(&:to_s).zip(Array.new(sub_vouchers.size) { 1 }).to_h)
    sub = Vouchertype.create!(
        :category => :bundle,
        :subscription => true,
        :price => 80.00,
        :name => 'Season Subscription 2',
        :season => Time.this_season,
        :offer_public => Vouchertype::ANYONE,
        :included_vouchers => sub_vouchers.map(&:id).map(&:to_s).zip(Array.new(sub_vouchers.size) { 1 }).to_h)
    sub = Vouchertype.create!(
          :category => :bundle,
          :subscription => true,
          :price => 90.00,
          :name => 'Season Subscription 3',
          :season => Time.this_season,
          :offer_public => Vouchertype::ANYONE,
          :included_vouchers => sub_vouchers.map(&:id).map(&:to_s).zip(Array.new(sub_vouchers.size) { 1 }).to_h)
  end

  desc "In tenant '#{StagingHelper::TENANT}', delete all sales data (vouchertypes, valid-vouchers, orders) but keep customers, shows, and show dates"
@@ -188,24 +172,15 @@ staging = namespace :staging do
  task :sell_subscriptions => :environment do
    StagingHelper::switch_to_staging!
    percent = (ENV['PERCENT'] || '50').to_i / 100.0
    sub_voucher1 = ValidVoucher.includes(:vouchertype).
      where(:vouchertypes => {:category => :bundle, :subscription => true, :price => 70.00}).
      first
    sub_voucher2 = ValidVoucher.includes(:vouchertype).
      where(:vouchertypes => {:category => :bundle, :subscription => true, :price => 80.00}).
    sub_voucher = ValidVoucher.includes(:vouchertype).
      where(:vouchertypes => {:category => :bundle, :subscription => true}).
      first
    sub_voucher3 = ValidVoucher.includes(:vouchertype).
      where(:vouchertypes => {:category => :bundle, :subscription => true, :price => 90.00}).
      first
    sub_vouchers = [sub_voucher1, sub_voucher2, sub_voucher3]

    customers = Customer.where('role >= 0 AND role<100') # hack: exclude special customers & admin
    customers = customers.sample(customers.size * percent * 0.5) # since will sell avg of 2 per pax
    customers.each do |customer|
      o = Order.create(:purchaser => customer, :processed_by => customer, :customer => customer,
        :purchasemethod => Purchasemethod.get_type_by_name('box_chk'))
      num_tix = [1,2,2,2,2,3,4].sample
      sub_voucher = sub_vouchers.sample()
      o.add_tickets_without_capacity_checks(sub_voucher, num_tix)
      o.finalize!
      StagingHelper::dot
@@ -261,4 +236,3 @@ staging = namespace :staging do
  end
end

