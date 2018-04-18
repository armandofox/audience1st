if ENV['RAILS_ENV'] == 'development'
  namespace :db do
    desc "Import all venues' databases schema by schema...yikes"
    task :import_venue => :environment do
      venue = ENV['VENUE'] or abort "must set VENUE=venuename"
      STDERR.puts "Copying #{venue}'s yaml dump..."
      system("scp -C audienc@audience1st.com:rails/#{venue}/current/db/data.yml #{Rails.root}/db/data.yml") or abort "Copy failed: #{$?}"
      STDERR.puts "Importing to schema..."
      system("TENANT=#{venue} rake db:data:load") or abort "Import failed: #{$?}"
    end
    desc "Set config values from venues.yml"
    task :load_config => :environment do
      venue = ENV['VENUE'] or abort "must set VENUE=venuename"
      c = YAML::load(IO.read("/Users/fox/Documents/fox/projects/vboadmin/venues.yml"))[venue]['application_yml']
      STDERR.puts "Setting options..."
      Apartment::Tenant.switch! venue
      Option.first.update_attributes!(
        :stripe_key => c['stripe_key'],
        :stripe_secret => c['stripe_secret'],
        :sendgrid_key_name => 'apikey',
        :sendgrid_key_value => c['sendgrid_api_value'],
        :stylesheet_url => c['stylesheet_url'],
        :mailchimp_key => c['mailchimp_key'],
        :sendgrid_domain => "#{venue}.audience1st.com" )
    end
  end
end
