Rails.application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # Need to explicitly set host for full-path URLs in testing environment
  routes.default_url_options[:host] = 'http://www.example.com'

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'
  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  # config.assets.enabled = true
  # config.serve_static_files = true
  # config.assets.debug = true
  # config.assets.compile = true
  # config.assets.digest = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = {
    :host => 'www.example.com', :protocol => 'http://'
  }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.log_level = :debug

  # Find n+1 query problems and unused eager-loads
  config.after_initialize do
    Bullet.enable = false       # change to 'true' to enable n+1 query logging
    Bullet.bullet_logger = true # log/bullet.log
  end

end
