# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.18'

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

  config.after_initialize do
    config.action_mailer.delivery_method = :test if Figaro.env.sandbox
  end
  
  # Add additional load paths for your own custom dirs
  additional_paths = Dir.glob(File.join Rails.root, "app/models/**/*").select { |f| File.directory? f }
  config.eager_load_paths += additional_paths
  config.autoload_paths += additional_paths

  config.active_record.timestamped_migrations = true

end
