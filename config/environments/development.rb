Rails.application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.delivery_method = :file
  config.action_mailer.raise_delivery_errors = true
  # config.log_level = :debug

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :stderr

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.enabled = true
  config.serve_static_files = true
  config.assets.debug = true
  config.assets.compile = true
  config.assets.digest = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Stripe payments: disable SSL verification for local testing
  require 'stripe'
  Stripe.verify_ssl_certs = false

end
