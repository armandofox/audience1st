require 'spec_helper'

describe 'Session routes', :type => :routing do
  before :all do ; @r = {:controller => 'sessions'}; end
  describe 'for new' do
    specify 'session' do
      {:get => '/session/new'}.should route_to @r.merge(:action => 'new')
    end
    specify 'session via login alias' do
      {:get => '/login'}.should route_to(@r.merge(:action => 'new'))
    end
  end
  describe 'for secret question' do
    specify 'request login page' do
      {:get => '/session/new_from_secret'}.should route_to @r.merge(:action => 'new_from_secret')
    end
    specify 'creation' do
      {:post => '/session/create_from_secret'}.should route_to @r.merge(:action => 'create_from_secret')
    end
  end
  specify 'enable/disable admin' do
    {:get => '/session/temporarily_disable_admin'}.should route_to(
        {:controller => 'sessions', :action => 'temporarily_disable_admin'})
    {:get => '/session/reenable_admin'}.should route_to(
      {:controller => 'sessions', :action => 'reenable_admin'})
  end

end

