require 'spec_helper'

describe 'Session routes', :type => :routing do
  before :all do ; @r = {:controller => 'sessions'}; end
  describe 'for new' do
    specify 'session' do
      {:get => '/session/new'}.should route_to @r.merge(:action => 'new')
    end
    specify 'session via login alias' do
      {:get => '/login'}.should route_to @r.merge(:action => 'new')
    end
  end
  describe 'for secret question' do
    specify 'request login page' do
      {:get => '/session/login_with_secret'}.should route_to @r.merge(:action => 'login_with_secret_session')
    end
    specify 'creation' do
      {:post => '/session/secret_question_create'}.should route_to @r.merge(:action => 'secret_question_create')
    end
  end
end

