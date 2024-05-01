# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.7.7'

# basic app components
gem 'pg', '0.20'                # Rails5: OK to upgrade to latest version
gem 'apartment', '>= 2.1.0'     # multi-tenancy: see README.md
gem 'rails', '5.0.1'

gem 'builder'
gem 'bundler', '1.17.3'
gem 'figaro'
gem 'sslrequirement'
gem 'haml'
gem 'gibbon'
gem 'i18n'
gem 'jbuilder', '~> 2.5'
gem 'json', '>= 2.0'            # see https://github.com/flori/json/issues/399 - avoid deprecation warning with json 1.8.6
gem 'newrelic_rpm'
gem 'nokogiri', '< 1.16.0'
gem 'platform-api'                # for restart task
#gem 'responders', '~> 2.0'
gem 'attr_encrypted', '< 4.0.0'
gem 'rake'
gem 'stripe'
gem 'will_paginate'

# asset pipeline
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'uglifier'

group :production do
  gem 'rack-timeout'              # prevent Heroku dynos from hanging up on timeout
  gem 'puma'
end

group :test do
  gem 'cucumber-rails', '< 3.0.0', :require => false
  gem 'capybara'
  gem 'chronic'
  gem 'launchy'
  gem 'rack-test'
  gem 'database_cleaner-active_record'
  gem 'email_spec'
  gem 'faker'
  gem 'fake_stripe'
  gem 'selenium-webdriver', require: false
  gem 'rspec-json_expectations'
  gem 'rails-controller-testing' # for assigns()
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
  gem 'vcr'
end

group :development do
  # gem 'derailed_benchmarks'
  # gem 'query_trail'
  # gem 'ruby-prof'
  # gem 'stackprof'
  # gem 'web-console'
end

group :development, :test do
  # the following really belong in a separate 'staging' environment
  gem 'factory_bot_rails'
  gem 'byebug'                  # 4
  #gem 'faye-websocket'
  #gem 'rb-readline'
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-html-matchers'
  gem 'rspec-collection_matchers' # should have(n).items, etc
  gem 'rspec-activemodel-mocks'   # mock_model(Customer), etc
  gem 'sqlite3', '1.3.13'
end
