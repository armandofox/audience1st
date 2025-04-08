require_relative 'boot'

require "rails/all"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Audience1st
  class Application < Rails::Application

    config.load_defaults 6.0
    config.autoloader = :classic

    config.active_storage.service = :local
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'
    config.active_record.default_timezone = :local
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.default_locale = 'en'

    config.assets.enabled = true
    config.eager_load = true

    config.after_initialize do
      config.action_mailer.delivery_method = :smtp
      Time.include CoreExtensions::Time::ShowtimeDateFormats
      Time.include CoreExtensions::Time::RoundedTo
      Time.include CoreExtensions::Time::Season
      Time.include CoreExtensions::Time::ToParam
      Date.include CoreExtensions::Date::Season
      String.include CoreExtensions::String::Name
      String.include CoreExtensions::String::Colorize
      ActiveModel::Errors.include ActiveModel::Errors::HtmlFormatter
    end
  end
end
