# read global configuration info
def read_yaml_file(f)
  YAML::load(ERB.new((IO.read("#{Rails.root}/config/#{f}.yml"))).result).symbolize_keys
end
POPUP_HELP =          read_yaml_file 'popup_help'
OPTION_DESCRIPTIONS = read_yaml_file 'option_descriptions'
APP_CONFIG =          read_yaml_file 'settings'
#ENV['TZ'] = APP_CONFIG[:timezone] || 'PST8PDT' # local timezone
APP_VERSION = IO.read("#{Rails.root}/REVISION").to_s.strip rescue "DEV"
