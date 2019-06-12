require 'rails_helper'

describe 'Customer routes for', :type => :routing do
  before :all do ; @r = {:controller => 'customers'}; end
  describe 'customer collection' do
    specify 'merging' do
      expect({:post => '/customers/finalize_merge'}).to route_to @r.merge(:action => 'finalize_merge')
      expect({:get => '/customers/merge'}).to route_to @r.merge(:action => 'merge')
    end
    specify 'searching' do
      expect({:get => '/customers/search'}).to route_to @r.merge(:action => 'search')
    end
    specify 'listing dups' do
      expect({:get => '/customers/list_duplicate'}).to route_to @r.merge(:action => 'list_duplicate')
    end
  end
  describe 'individual customers' do
    specify 'change password' do
      [:get, :post].each do |action|
        expect({action => '/customers/333/change_password_for'}).to route_to @r.merge(
          :action => 'change_password_for', :id => '333')
      end
    end
    specify 'user self-creation' do
      expect({:post => '/customers/user_create'}).to route_to @r.merge(:action => 'user_create')
    end
    specify 'changing secret question' do
      [:get, :post].each do |action|
        expect({action => '/customers/333/change_secret_question'}).to route_to @r.merge(
          :action => 'change_secret_question', :id => '333')
      end
    end
  end
end
