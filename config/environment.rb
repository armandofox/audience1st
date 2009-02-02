# Be sure to restart your web server when you modify this file.

require 'yaml'

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'
RAILS_GEM_VERSION = '1.2.3'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here

  # Skip frameworks you're not going to use
  #config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/reports )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')

  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql


  config.after_initialize do
    if RAILS_ENV == 'production'
      # bug: this if clause should just be moved to environments/production.rb,
      # but currently you're allowed only a single after_initialize hook.
      ExceptionNotifier.sender_address =
        %("EXCEPTION NOTIFIER" <bugs@audience1st.com>)
      ExceptionNotifier.exception_recipients =
        %w(armandofox@gmail.com)
    end
    # are we operating in 'sandbox' mode?  if so, some features like
    # "real" CC purchases and email sending are turned off or
    # handled differently.
    SANDBOX = (RAILS_ENV != 'production'  ||
               Option.value(:sandbox).to_i != 0)
    if SANDBOX
      ActionMailer::Base.delivery_method = :test
    end
    # read global configuration info
    APP_CONFIG =  YAML::load(ERB.new((IO.read("#{RAILS_ROOT}/config/settings.yml"))).result).symbolize_keys
    MESSAGES = APP_CONFIG[:messages].symbolize_keys
    ENV['TZ'] = APP_CONFIG[:timezone] || 'PST8PDT' # local timezone
    APP_VERSION = IO.read("#{RAILS_ROOT}/REVISION").to_s.strip rescue "DEV"
  end

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# session key name
ActionController::Base.session_options[:session_key] = 'audience1st_session_id'


# Enable Google Analytics (http://svn.rubaidh.com/plugins/trunk/google_analytics)

Rubaidh::GoogleAnalytics.tracker_id = 'UA-4613071-1'
Rubaidh::GoogleAnalytics.domain_name  = 'www.audience1st.com'
Rubaidh::GoogleAnalytics.environments = ['production']
