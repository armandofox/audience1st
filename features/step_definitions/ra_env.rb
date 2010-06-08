
Before do
  Fixtures.reset_cache
  fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
  Fixtures.create_fixtures(fixtures_folder, "customers")
  require File.join(RAILS_ROOT, 'spec', 'support', 'facebooker_stubs_for_restful_auth.rb')
end

# Make visible for testing
ApplicationController.send(:public, :logged_in?, :current_user, :current_admin, :authorized?)
