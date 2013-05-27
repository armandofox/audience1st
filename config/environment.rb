# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.11'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


Rails::Initializer.run do |config|
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  # config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  # session key name
  config.action_controller.session_store = :active_record_store
  #ActionController::Base.session_options[:session_key] = 'audience1st_session_id'

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/reports )

  config.active_record.timestamped_migrations = true

  config.gem 'i18n', :version => '~> 0.4.0'
  config.gem 'money'
  config.gem 'active_merchant'
  config.gem 'haml'
  config.gem 'nokogiri' # , :version => '1.3.3'
  config.gem 'dbf',  :version => '>= 1.2.8'
  config.gem 'builder',  :version => '>= 2.1.2'
  config.gem 'mechanize'
  config.gem 'ruport'
  config.gem 'stripe'
  
end

# For use if we ever switch to Bundler:
# source :rubygems

# gem 'capistrano'
# gem 'mysql'

# gem 'rails', '2.3.5'
# gem 'i18n', '~> 0.4.0'          # can remove once upgrade to 2.3.11
# gem 'activemerchant'
# gem 'haml'
# gem 'nokogiri', '1.3.3'
# gem 'dbf',  '>= 1.2.8'
# gem 'builder',  '>= 2.1.2'
# gem 'mechanize'
# gem 'money'
# gem 'ruport'
# gem 'acts_as_reportable'
# gem 'stripe'


# group :development do
#   gem 'ruby-debug'
# end

# group :test do
#   gem 'cucumber-rails', '>= 0.3.0'
#   gem 'rspec-rails', '>= 1.3.2'
#   gem 'launchy'
#   gem 'webrat', '>= 0.7.1'
#   gem 'capybara'
#   gem 'fakeweb'
#   gem 'ZenTest'
#   gem 'timecop'
#   gem 'chronic'
# end
