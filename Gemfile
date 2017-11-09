# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.3.1'

gem 'pg'
gem 'acts_as_reportable'
gem 'builder'
gem 'bundler'
# gem 'constant_contact'
gem 'dbf'
gem 'dbi'
gem 'figaro'
gem 'travis'
gem 'sslrequirement'
gem 'haml'
gem 'hominid'
gem 'i18n'
gem 'jbuilder', '~> 2.0'        # 4
gem 'jquery-rails'              # 4
gem 'json'
gem 'mechanize'
gem 'mysql'
gem 'nokogiri'
gem 'pothoven-attachment_fu'
gem 'protected_attributes'      # remove once we migrate to Strong Parameters
gem 'rails', '4.2.9'            # 4
gem 'rake'
gem 'ruport'
# stripe depends on rest-client and json, but we can't use the latest version of
# those until upgrade to ruby >= 1.9.2
gem 'rest-client'
gem 'stripe'
gem 'thor', '0.19.1'
gem 'will_paginate'
gem 'simplecov'
group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
end

group :test do
  gem 'cucumber'
  gem 'cucumber-rails', :require => false
  gem 'capybara'
  gem 'poltergeist'
  gem 'rspec-its'
  gem 'rspec-html-matchers'
  gem 'simplecov', :require => false
  gem 'webmock'
end
group :production do
  gem 'mysql2', '~> 0.3.18'
end
group :development, :test do
  # cucumber and capybara
  gem 'byebug'                  # 4
  gem 'pry'
  gem 'listen', '~> 2.2'
  gem 'guard-rspec', :require => false
  gem 'guard-cucumber'
  gem 'minitest'
  gem 'capistrano'
  gem 'faye-websocket'
  gem 'database_cleaner'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'rb-readline'
  gem 'rubyzip'
  gem 'mime-types'
  gem 'chronic'
  gem 'fakeweb'
  gem 'launchy'
  gem 'faker'
  gem 'rack-test'
  gem 'sdoc', '~> 0.4.0'
  gem 'coveralls', :require => false
  gem 'rspec-rails'
  gem 'rspec-collection_matchers' # should have(n).items, etc
  gem 'rspec-activemodel-mocks'   # mock_model(Customer), etc
  gem 'sqlite3'
  gem 'timecop'
  gem 'railroady'
end
