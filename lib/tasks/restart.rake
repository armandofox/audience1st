require 'platform-api'

a1 = namespace :a1 do
  app_name = 'audience1st'
  log_regex = /^\S+\s+.*memory_total=(\d+\.\d+)MB.*memory_quota=(\d+\.\d+)MB/
  desc "Restart all dynos if any dyno has exceeded its memory quota"
  task :restart_if_memory_exceeded => :environment do
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_API_KEY'])
    log = heroku.log_session.create(app_name)
    lines = Net::HTTP.get(URI(log['logplex_url'])).split( /\n/ ) # retrieves ~10 log lines
    lines.each do |line|
      next unless (line =~ log_regex)
      used,max = $1.to_f, $2.to_f
      puts "  >>> used #{used}MB / #{max}MB" 
      if used >= max
        puts ": RESTARTING\n"
        # restart all dynos
        heroku.dyno.restart_all(app_name)
        break
      else
        puts "\n"
      end
    end
    NewRelic::Agent.notice_error(ex)
  end
end
