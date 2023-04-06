# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.7.7'

# basic app components
gem 'pg', '0.20'                # Rails5: OK to upgrade to latest version
gem 'apartment', '>= 2.1.0'     # multi-tenancy: see README.md
gem 'rails', '4.2.11.1'

gem 'where-or'                  # backport from Rails 5; remove when upgrading

gem 'bigdecimal', '1.3.5'       # @see https://stackoverflow.com/questions/60226893/rails-nomethoderror-undefined-method-new-for-bigdecimalclass - this can be removed for Rails 5
gem 'builder'
gem 'bundler', '1.17.3'
gem 'figaro'
gem 'sslrequirement'
gem 'haml'
gem 'gibbon'
gem 'i18n'
gem 'jbuilder', '~> 2.0'
gem 'jquery-rails', '= 4.0.5'
gem 'jquery-ui-rails', '= 5.0.5'
gem 'json', '>= 2.0'            # see https://github.com/flori/json/issues/399 - avoid deprecation warning with json 1.8.6
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.12'
gem 'protected_attributes'      # remove once we migrate to Strong Parameters
gem 'responders', '~> 2.0'
gem 'attr_encrypted'            # attr_encrypted must load AFTER protected_attributes (https://github.com/attr-encrypted/attr_encrypted/issues/107)
gem 'rake'
gem 'scout_apm'
gem 'stripe'
gem 'will_paginate'

# asset pipeline
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'sassc-rails'
gem 'uglifier'

group :production do
  gem 'rack-timeout'              # prevent Heroku dynos from hanging up on timeout
  gem 'puma-heroku'
  gem 'puma', '>= 4.3.8'
  gem 'rails_12factor'
end

group :test do
  gem 'cucumber', '~> 3.0.0'
  gem 'cucumber-rails', :require => false
  gem 'capybara', '~> 3.0'
  gem 'chronic'
  gem 'launchy'
  gem 'rack-test'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'faker'
  gem 'fake_stripe'
  gem 'webdrivers','~> 5.0', require: false
  gem 'rspec-json_expectations'
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
  gem 'web-console', '~> 2.0'
end

group :development, :test do
  # the following really belong in a separate 'staging' environment
  gem 'factory_bot_rails'       # used by fake_data stuff
  gem 'bullet'                # show needed/needless eager loads
  gem 'byebug'                  # 4
  gem 'pry'
  gem 'listen', '~> 2.2'
  gem 'faye-websocket'
  #gem 'rb-readline'
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-html-matchers'
  gem 'rspec-collection_matchers' # should have(n).items, etc
  gem 'rspec-activemodel-mocks'   # mock_model(Customer), etc
  gem 'sqlite3', '1.3.13'
  gem 'traceroute'              # find unused routes
end
