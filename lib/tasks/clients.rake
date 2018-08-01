require 'apartment/migrator'

module Audience1stRakeTasks
  def check_vars!
    %w(TENANT STRIPE_KEY STRIPE_SECRET SENDGRID_KEY VENUE_FULLNAME).each do |var|
      raise "#{var} is required" unless ENV[var]
    end
  end
end

a1client = namespace :a1client  do
  desc "Add and seed new client named TENANT.  Don't forget to also add the tenant name to the `tenant_names` runtime environment variable, and set DNS resolution for <tenant>.audience1st.com."
  task :drop => :environment do
    raise 'TENANT is required' unless (tenant = ENV["TENANT"])
    puts "Dropping '#{tenant}'..."
    Apartment::Tenant.drop(tenant)
  end

  task :create => :environment do
    raise 'TENANT is required' unless (tenant = ENV["TENANT"])
    puts "Creating '#{tenant}'..."
    Apartment::Tenant.create(tenant)
    puts "Seeding '#{tenant}'..."
    Apartment::Tenant.switch(tenant) do
      Apartment::Tenant.seed
    end
    puts "done"
  end

  desc "Configure (new) client named TENANT using VENUE_FULLNAME, SENDGRID_KEY, STRIPE_KEY, STRIPE_SECRET, all of which are required. Use underscores for spaces in VENUE_FULLNAME. Don't forget to also add the tenant name to the `tenant_names` runtime environment variable, and set DNS resolution for <tenant>.audience1st.com."
  task :configure => :environment do
    Audience1stRakeTasks.check_vars!
    Apartment::Tenant.switch(ENV['TENANT']) do
      Option.first.update_attributes!(
        :sendgrid_domain    => "#{ENV['TENANT']}.audience1st.com",
        :sendgrid_key_value => ENV['SENDGRID_KEY'],
        :stripe_key         => ENV['STRIPE_KEY'],
        :stripe_secret      => ENV['STRIPE_SECRET'],
        :venue              => ENV['VENUE_FULLNAME'].gsub(/_/,' '),
        :staff_access_only  => true )
    end
  end

  desc "Set up new client TENANT using VENUE_FULLNAME, SENDGRID_KEY, STRIPE_KEY, STRIPE_SECRET, all of which are required."
  task :setup => :environment do
    Audience1stRakeTasks.check_vars!
    a1client['create'].invoke
    a1client['configure'].invoke
  end
end
