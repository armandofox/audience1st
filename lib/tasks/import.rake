namespace :db do
  desc "Import all venues' databases schema by schema...yikes"
  task :import_venue => :environment do
    venue = ENV['VENUE'] or abort "must set VENUE=venuename"
    STDERR.puts "Copying #{venue}'s yaml dump..."
    system("scp -C audienc@audience1st.com:rails/#{venue}/current/db/data.yml #{Rails.root}/db/data.yml") or abort "Copy failed: #{$?}"
    STDERR.puts "Importing to schema..."
    system("TENANT=#{venue} rake db:data:load") or abort "Import failed: #{$?}"
  end
end

    
