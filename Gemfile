# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.3.1'

# basic app components
gem 'pg', '~> 0.21'
gem 'apartment', '>= 2.1.0'     # multi-tenancy: see README.md
gem 'rails', '4.2.9'
gem 'rack-timeout'              # prevent Heroku dynos from hanging up on timeout

gem 'where-or'                  # backport from Rails 5; remove when upgrading

gem 'builder'
gem 'bundler'
gem 'figaro'
gem 'sslrequirement'
gem 'haml'
gem 'gibbon'
gem 'i18n'
gem 'jbuilder', '~> 2.0'
gem 'jquery-rails', '= 4.0.5'
gem 'jquery-ui-rails', '= 5.0.5'
gem 'nokogiri'
gem 'pothoven-attachment_fu'
gem 'protected_attributes'      # remove once we migrate to Strong Parameters
gem 'responders', '~> 2.0'
gem 'attr_encrypted'            # attr_encrypted must load AFTER protected_attributes (https://github.com/attr-encrypted/attr_encrypted/issues/107)
gem 'rake'
gem 'stripe'
gem 'will_paginate'

# asset pipeline
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'uglifier'
gem 'sassc-rails'

group :production do
  gem 'newrelic_rpm'
  gem 'puma-heroku'
  gem 'puma'
  gem 'rails_12factor'
end

group :test do
  gem 'cucumber', '~> 2.0'
  gem 'cucumber-rails', '1.5.0', :require => false
  gem 'capybara'
  gem 'fake_stripe'
  gem 'poltergeist'
  gem 'rspec-its'
  gem 'rspec-html-matchers'
  gem 'simplecov', :require => false
  gem 'spring'                  # for 'guard'
  gem 'webmock'
  gem 'vcr'
end

group :development do
  gem 'derailed_benchmarks'
  # gem 'query_trail'
  gem 'ruby-prof'
  gem 'stackprof'
  gem 'web-console', '~> 2.0'
  gem 'spring-commands-rspec'   # for use with Guard
end

group :development, :test do
  # the following really belong in a separate 'staging' environment
  gem 'faker', :git => 'https://github.com/armandofox/faker' # needed in production too,for adding fake data to staging server
  gem 'factory_bot_rails'                                    # used by fake_data stuff

  gem 'bullet'
  # cucumber and capybara
  gem 'yaml_db', :git => 'https://github.com/armandofox/yaml_db'
  gem 'byebug'                  # 4
  gem 'pry'
  gem 'listen', '~> 2.2'
  gem 'guard-rspec', :require => false
  gem 'guard-cucumber'
  gem 'minitest'
  gem 'faye-websocket'
  gem 'database_cleaner'
  gem 'rb-readline'
  gem 'rubyzip'
  gem 'mime-types'
  gem 'chronic'
  gem 'fakeweb'
  gem 'launchy'
  gem 'rack-test'
  gem 'sdoc', '~> 0.4.0'
  gem 'coveralls', :require => false
  gem 'rspec-rails'
  gem 'rspec-collection_matchers' # should have(n).items, etc
  gem 'rspec-activemodel-mocks'   # mock_model(Customer), etc
  gem 'sqlite3'
  gem 'timecop'
  gem 'traceroute'
end
