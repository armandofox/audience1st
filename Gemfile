# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.3.1'

# basic app components
gem 'pg', '~> 0.21'
gem 'apartment', '>= 2.1.0'     # multi-tenancy: see README.md
gem 'puma'
gem 'rails', '4.2.9'

gem 'acts_as_reportable'
gem 'builder'
gem 'bundler'
gem 'figaro'
gem 'sslrequirement'
gem 'haml'
gem 'hominid'
gem 'i18n'
gem 'jbuilder', '~> 2.0'        # 4
gem 'jquery-rails'              # 4
gem 'mechanize'
gem 'nokogiri'
gem 'pothoven-attachment_fu'
gem 'protected_attributes'      # remove once we migrate to Strong Parameters
gem 'attr_encrypted'            # attr_encrypted must load AFTER protected_attributes (https://github.com/attr-encrypted/attr_encrypted/issues/107)
gem 'rake'
gem 'ruport'
gem 'stripe'
gem 'will_paginate'

group :production do
  gem 'newrelic_rpm'
  gem 'puma-heroku'
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
  gem 'webmock'
end

group :development do
  gem 'derailed_benchmarks'
  gem 'stackprof'
  gem 'web-console', '~> 2.0'
end

group :development, :test do
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
  gem 'factory_bot_rails'
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
