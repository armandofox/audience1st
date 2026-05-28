require_relative "boot"

require "rails"

# if we ever use activestorage, replace the below with `require "rails/all"`

require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine" # for managing externally-stored blobs
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine" # for receiving inbound emails
# require "action_text/engine"    # rich text editor support -requires active_storage
require "action_view/railtie"
# require "action_cable/engine"   # websockets support
# require "rails/test_unit/railtie"



# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Audience1st
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # without this, zeitwerk complains that model names aren't nested properly, but
    # in order to make single-table inheritance work, we can't nest them that way
    Rails.autoloaders.main.collapse(Rails.root.join("app/models/items"))
    Rails.autoloaders.main.collapse(Rails.root.join("app/models/reports"))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Pacific Time (US & Canada)'
    config.active_record.default_timezone = :local

    config.eager_load_paths << Rails.root.join("lib")
    
  end
end
