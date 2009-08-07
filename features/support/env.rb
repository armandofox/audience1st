# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "cucumber"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'

# Comment out the next line if you don't want Cucumber Unicode support
require 'cucumber/formatter/unicode'

# Comment out the next line if you don't want transactions to
# open/roll back around each scenario
Cucumber::Rails.use_transactional_fixtures

#Seed the DB
Fixtures.reset_cache
fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
Fixtures.create_fixtures(fixtures_folder, fixtures)

# Comment out the next line if you want Rails' own error handling
# (e.g. rescue_action_in_public / rescue_responses / rescue_from)
Cucumber::Rails.bypass_rescue

require 'webrat'
require 'cucumber/webrat/table_locator' # Lets you do table.diff!(table_at('#my_table').to_a)

Webrat.configure do |config|
  config.mode = :rails
end

require 'cucumber/rails/rspec'
require 'webrat/core/matchers'


# Before do
#   Fixtures.reset_cache
#   fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
#   fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
#   Fixtures.create_fixtures(fixtures_folder, fixtures)
# end

module FixtureAccess

  def self.extended(base)

    Fixtures.reset_cache
    fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
    fixtures += Dir[File.join(fixtures_folder, '*.csv')].map {|f| File.basename(f, '.csv') }

    Fixtures.create_fixtures(fixtures_folder, fixtures)    # This will populate the test database tables

    (class << base; self; end).class_eval do
      @@fixture_cache = {}
      fixtures.each do |table_name|
        table_name = table_name.to_s.tr('.', '_')
        define_method(table_name) do |*fixture_symbols|
          @@fixture_cache[table_name] ||= {}

          instances = fixture_symbols.map do |fixture_symbol|
            if fix = Fixtures.cached_fixtures(ActiveRecord::Base.connection, table_name)[fixture_symbol.to_s]
              @@fixture_cache[table_name][fixture_symbol] ||= fix.find  # find model.find's the instance
            else
              raise StandardError, "No fixture with name '#{fixture_symbol}' found for table '#{table_name}'"
            end
          end
          instances.size == 1 ? instances.first : instances
        end
      end
    end
  end

end

