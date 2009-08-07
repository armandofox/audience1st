# read global configuration info
APP_CONFIG =  YAML::load(ERB.new((IO.read("#{RAILS_ROOT}/config/settings.yml"))).result).symbolize_keys
MESSAGES = APP_CONFIG[:messages].symbolize_keys
ENV['TZ'] = APP_CONFIG[:timezone] || 'PST8PDT' # local timezone
APP_VERSION = IO.read("#{RAILS_ROOT}/REVISION").to_s.strip rescue "DEV"
