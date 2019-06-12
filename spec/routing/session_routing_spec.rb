require 'rails_helper'

describe 'Session routes', :type => :routing do
  before :all do ; @r = {:controller => 'sessions'}; end
  describe 'for new' do
    specify 'session' do
      expect({:get => '/session/new'}).to route_to @r.merge(:action => 'new')
    end
    specify 'session via login alias' do
      expect({:get => '/login'}).to route_to @r.merge(:action => 'new')
    end
  end
  describe 'for secret question' do
    specify 'request login page' do
      expect({:get => '/session/new_from_secret'}).to route_to @r.merge(:action => 'new_from_secret')
    end
    specify 'creation' do
      expect({:post => '/session/create_from_secret'}).to route_to @r.merge(:action => 'create_from_secret')
    end
  end
  specify 'enable/disable admin' do
    expect({:get => '/session/temporarily_disable_admin'}).to route_to(
        {:controller => 'sessions', :action => 'temporarily_disable_admin'})
    expect({:get => '/session/reenable_admin'}).to route_to(
      {:controller => 'sessions', :action => 'reenable_admin'})
  end

end

