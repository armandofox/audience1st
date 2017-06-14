# Be sure to restart your server when you modify this file

# Load the Rails application.
require File.expand_path('../application', __FILE__)


Rails.application.configure do
  config.after_initialize do
    config.action_mailer.delivery_method = :test if Figaro.env.sandbox
  end
  
  # Add additional load paths for your own custom dirs
  additional_paths = Dir.glob(File.join Rails.root, "app/models/**/*").select { |f| File.directory? f }
  config.eager_load_paths += additional_paths
  config.autoload_paths += additional_paths

  config.active_record.timestamped_migrations = true

end

# Initialize the Rails application.
Rails.application.initialize!

