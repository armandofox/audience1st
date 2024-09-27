require 'apartment/migrator'

module Audience1stRakeTasks
  def self.check_vars!
    %w(TENANT VENUE_FULLNAME).each do |var|
      raise "#{var} is required" unless ENV[var]
    end
  end
end

a1client = namespace :a1client  do
  desc "Use `heroku run -e \"TENANT=tenant_name\" rake a1client:drop` to drop client named `tenant_name` by deleting its schema.  Don't forget to also remove the tenant name from `tenant_names` runtime environment variable, and unset DNS resolution for <tenant>.audience1st.com."
  task :drop => :environment do
    raise 'TENANT is required' unless (tenant = ENV["TENANT"])
    puts "Dropping '#{tenant}'..."
    Apartment::Tenant.drop(tenant)
    puts "Dropped.  Don't forget to remove from Heroku DNS and from `tenant_names` envar."
  end

  desc "Add and seed new client named TENANT, but you probably should be using the a1client:provision task instead."
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

  desc "Configures sender domain, venue full name,  admin@audience1st.com admin user with ADMIN_PASSWORD or a random password if not given, boxoffice & help email addresses, and staff-only access for the (new) client named TENANT using VENUE_FULLNAME, using underscores for spaces. Don't forget to also add the tenant name to the `tenant_names` runtime environment variable, set DNS resolution for <tenant>.audience1st.com, and add the subdomain explicitly to Sendgrid settings."
  task :configure => :environment do
    Audience1stRakeTasks.check_vars!
    tenant = ENV['TENANT']
    Apartment::Tenant.switch(tenant) do
      Option.first.update_attributes!(
        :sender_domain      => "mail.audience1st.com",
        :venue              => ENV['VENUE_FULLNAME'].gsub(/_/,' '),
        :box_office_email   => "boxoffice@#{tenant}.org",
        :help_email         => "help@#{tenant}.org",
        :staff_access_only  => true )
      admin_pw = ENV['ADMIN_PASSWORD'] || ('a'..'z').to_a.shuffle[0,8].join
      Customer.find_by(:first_name => 'Super', :last_name => 'Administrator').
        update_attributes!(:password => admin_pw)
    end
    puts "Sender domain configured, venue full name/help email/boxoffice email set up (educated guesses), admin password randomized, and staff-only access enabled for #{ENV['VENUE_FULLNAME']} (#{tenant})"
  end

  desc "Use `heroku run -e \"TENANT=tenantname;VENUE_FULLNAME=name with spaces\" rake a1client:provision` to set up new client TENANT as VENUE_FULLNAME."
  task :provision => :environment do
    Audience1stRakeTasks.check_vars!
    a1client['create'].invoke
    a1client['configure'].invoke
    puts "Client provisioned. Next: Set up DNS subdomain resolution in Heroku, add to tenant_names envar, and configure Stripe keys."
  end

  desc 'In preparation for importing to tenant TO, dump contents of tenant FROM (schema) on APP (Heroku app name) into ${TO}.pgdump, renaming all schema references to TO for importing to a destination schema (which must not already exist)'
  task :dump_schema => :environment do
    raise 'FROM is required' unless (from = ENV["FROM"])
    raise 'TO is required' unless (to = ENV["TO"])
    raise 'APP is required' unless (app = ENV["APP"])
    sed = %Q{perl -pe 's/#{from};/"#{to}";/g, s/#{from}\./"#{to}"./g, s/"#{from}"\./"#{to}"./g'}
    cmd = %Q{heroku run pg_dump -Fp --inserts --no-privileges --no-owner '$DATABASE_URL' --schema=#{from} -a #{app} } <<
          %Q{ | #{sed}  > #{to}.pgdump } 
    puts cmd
    if system(cmd)
      puts "Done.  Use `heroku pg:psql -a appname < #{to}.pgdump` to import schema."
    else
      puts "Error: #{$?}"
    end
  end

end
