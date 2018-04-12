# -*- mode: ruby; -*-
source 'https://rubygems.org'
ruby '1.8.7'

gem 'acts_as_reportable', '1.1.1'
gem 'builder'
gem 'bundler'
gem 'constant_contact', '1.4.0'
gem 'dbf', '1.2.8'
gem 'dbi', '0.4.5'
gem 'erubis'                    # for html-escape XSS protection; not needed for Rails >=3
gem 'figaro', '~> 1.0'
gem 'sslrequirement'
gem 'haml', '~> 3.1.8'
gem 'i18n', '0.4.1'
gem 'mechanize', '1.0.0'
gem 'mysql', '2.8.1'
gem 'nokogiri', '1.4.3.1'
gem 'rails', '2.3.18'
gem 'rake', '10.3.1'
gem 'ruport', '1.6.3'
# stripe depends on rest-client and json, but we can't use the latest version of
# those until upgrade to ruby >= 1.9.2
gem 'rest-client', '~> 1.4'     
gem 'json', '1.8.1'
gem 'stripe', '1.22.0'
gem 'will_paginate', '2.3.16'

gem 'yaml_db'

group :development, :test do
  # cucumber and capybara
  gem 'ruby-debug'
  gem 'ZenTest'
  gem 'autotest-rails'
  gem 'autotest-fsevent', :git => 'https://github.com/svoop/autotest-fsevent.git'
  gem 'minitest'
  gem 'capistrano', '2.5.10'

  # for Ruby 1.8.7/Rails 2.3, we need phantomjs <=1.9.8 and faye-websocket 0.4.7
  # (https://github.com/teampoltergeist/poltergeist/issues/320)
  gem 'capybara', '1.1.4'
  gem 'poltergeist', '1.0.2'
  gem 'faye-websocket', '0.4.7'

  gem 'database_cleaner', '1.0.1'
  gem 'factory_girl', '~> 2.6.4'
  gem 'rubyzip', '~> 0.9.9'
  gem 'mime-types', '1.24'
  gem 'chronic', '0.9.1'
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'fakeweb'
  gem 'launchy'
  gem 'rack-test', '0.5.7'
  gem 'rdoc'
  gem 'rcov'
  gem 'rspec-rails', '1.3.4'
  gem 'sqlite3'
  gem 'timecop', '0.3.5'
end
