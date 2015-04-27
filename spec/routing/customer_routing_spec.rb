require 'spec_helper'

describe 'Customer routes for', :type => :routing do
  before :all do ; @r = {:controller => 'customers'}; end
  describe 'utility' do
    specify 'autocomplete' do
      [:get, :post].each do |action|
        {action => '/customers/auto_complete_for_customer_full_name'}.should route_to(
          @r.merge(:action => 'auto_complete_for_customer_full_name'))
      end
    end
    specify 'enable/disable admin' do
      [:get, :post].each do |action|
        {action => '/customers/temporarily_disable_admin'}.should route_to(
          @r.merge(:action => 'temporarily_disable_admin'))
        {action => '/customers/reenable_admin'}.should route_to(
          @r.merge(:action => 'reenable_admin'))
      end
    end
  end
  describe 'customer collection' do
    specify 'merging' do
      {:post => '/customers/finalize_merge'}.should route_to @r.merge(:action => 'finalize_merge')
      {:get => '/customers/merge'}.should route_to @r.merge(:action => 'merge')
    end
    specify 'searching' do
      {:get => '/customers/search'}.should route_to @r.merge(:action => 'search')
      {:get => '/customers/lookup'}.should route_to @r.merge(:action => 'lookup') # obsolete?
      {:post => '/customers/lookup'}.should route_to @r.merge(:action => 'lookup') # obsolete?
    end
    specify 'listing dups' do
      {:get => '/customers/list_duplicate'}.should route_to @r.merge(:action => 'list_duplicate')
    end
  end
  describe 'individual customers' do
    specify 'change password' do
      [:get, :post].each do |action|
        {action => '/customers/333/change_password_for'}.should route_to @r.merge(
          :action => 'change_password_for', :id => '333')
      end
    end
    specify 'user self-creation' do
      {:post => '/customers/user_create'}.should route_to @r.merge(:action => 'user_create')
    end
    specify 'changing secret question' do
      [:get, :post].each do |action|
        {action => '/customers/333/change_secret_question'}.should route_to @r.merge(
          :action => 'change_secret_question', :id => '333')
      end
    end
  end
end
