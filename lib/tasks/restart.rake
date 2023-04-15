require 'platform-api'

a1 = namespace :a1 do
  APP_NAME = 'a1-staging'
  LOG_REGEX = /^\S+\s+.*memory_total=(\d+\.\d+)MB.*memory_quota=(\d+\.\d+)MB/
  desc "Restart all dynos if any dyno has exceeded its memory quota"
  task :restart => :environment do
    begin
      heroku = PlatformAPI.connect_oauth(ENV['HEROKU_API_KEY'])
      log = heroku.log_session.create(APP_NAME)
      lines = Net::HTTP.get(URI(log['logplex_url'])).split( /\n/ ) # retrieves ~10 log lines
      #if lines.any? { |line| (line =~ LOG_REGEX) and ($1.to_f >= $2.to_f) }
      if lines.any? { |line| (line =~ LOG_REGEX)  }
        # restart all dynos
        puts "Restarting: #{$1} #{$2}"
      else
        puts %Q{Nothing found in #{lines.join("\n")}}
      end
    rescue Exception => ex
      raise ex
      NewRelic::Agent.notice_error(ex)
    end
  end
end
