# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '2.3.1'

gem 'acts_as_reportable'
gem 'builder'
gem 'bundler'
# gem 'constant_contact'
gem 'dbf'
gem 'dbi'
gem 'figaro'
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
gem 'rails', '4.2.6'            # 4
gem 'rake'
gem 'ruport'
# stripe depends on rest-client and json, but we can't use the latest version of
# those until upgrade to ruby >= 1.9.2
gem 'rest-client'
gem 'sass-rails', '~> 5.0'      # 4
gem 'turbolinks'                # 4
gem 'uglifier', '>= 1.3.0'      # 4
gem 'stripe'
gem 'thor', '0.19.1'
gem 'will_paginate'

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
end

group :development, :test do
  # cucumber and capybara
  gem 'byebug'                  # 4
  gem 'ZenTest'
  gem 'autotest-rails'
  gem 'autotest-fsevent', :git => 'https://github.com/svoop/autotest-fsevent.git'
  gem 'minitest'
  gem 'capistrano'
  gem 'faye-websocket'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'rb-readline'
  gem 'rubyzip'
  gem 'mime-types'
  gem 'chronic'
  gem 'fakeweb'
  gem 'launchy'
  gem 'rack-test'
  gem 'sdoc', '~> 0.4.0'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'sqlite3'
  gem 'timecop'
end
