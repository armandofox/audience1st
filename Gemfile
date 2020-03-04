# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.5.5'

# basic app components
gem 'pg', '~> 0.21'
gem 'apartment', '>= 2.1.0'     # multi-tenancy: see README.md
gem 'rails', '4.2.11.1'

gem 'where-or'                  # backport from Rails 5; remove when upgrading

gem 'builder'
gem 'bundler', '1.17.2'
gem 'figaro'
gem 'sslrequirement'
gem 'haml'
gem 'gibbon'
gem 'i18n'
gem 'jbuilder', '~> 2.0'
gem 'jquery-rails', '= 4.0.5'
gem 'jquery-ui-rails', '= 5.0.5'
gem 'nokogiri'
gem 'protected_attributes'      # remove once we migrate to Strong Parameters
gem 'responders', '~> 2.0'
gem 'attr_encrypted'            # attr_encrypted must load AFTER protected_attributes (https://github.com/attr-encrypted/attr_encrypted/issues/107)
gem 'rake'
gem 'stripe'
gem 'will_paginate'

# asset pipeline
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'sassc-rails'
gem 'uglifier'

group :production do
  gem 'rack-timeout'              # prevent Heroku dynos from hanging up on timeout
  gem 'newrelic_rpm'
  gem 'puma-heroku'
  gem 'puma', '~> 3.12.4'
  gem 'rails_12factor'
end

group :test do
  gem 'cucumber', '~> 3.0.0'
  gem 'cucumber-rails', :require => false
  gem 'capybara', '~> 3.0'
  gem 'chronic'
  gem 'launchy'
  gem 'rack-test'
  gem 'coveralls', :require => false
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'fake_stripe'
  gem 'poltergeist'
  gem 'rspec-json_expectations'
  gem 'simplecov', :require => false
  gem 'spring'                  # for 'guard'
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
  gem 'sdoc', '~> 0.4.0'
end

group :development, :test do
  # the following really belong in a separate 'staging' environment
  gem 'faker', :git => 'https://github.com/armandofox/faker'
  gem 'factory_bot_rails'       # used by fake_data stuff
  gem 'bullet'                # show needed/needless eager loads
  gem 'byebug'                  # 4
  gem 'pry'
  gem 'listen', '~> 2.2'
  gem 'guard-rspec', :require => false
  gem 'guard-cucumber'
  gem 'spring-commands-rspec'   # for use with Guard
  gem 'minitest'
  gem 'faye-websocket'
  gem 'rb-readline'
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-html-matchers'
  gem 'rspec-collection_matchers' # should have(n).items, etc
  gem 'rspec-activemodel-mocks'   # mock_model(Customer), etc
  gem 'sqlite3'
  gem 'traceroute'              # find unused routes
end
