require 'spec_helper'

describe 'Session routes', :type => :routing do
  before :all do ; @r = {:controller => 'sessions'}; end
  describe 'for new' do
    specify 'session' do
      {:get => '/sessions/new'}.should route_to @r.merge(:action => 'new')
    end
    specify 'session via login alias' do
      {:get => '/login'}.should route_to @r.merge(:action => 'new')
    end
  end
  describe 'for secret question' do
    specify 'login page' do
      {:get => '/login_with_secret'}.should route_to @r.merge(:action => 'new_from_secret_question')
    end
    specify 'creation' do
      {:post => '/create_from_secret_question'}.should route_to @r.merge(:action => 'create_from_secret-question')
    end
  end
end

