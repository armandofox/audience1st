require 'spec_helper'

describe "AJAX responder routes", :type => :routing do
  specify 'autocomplete' do
    [:get, :post].each do |action|
      {action => '/ajax/auto_complete_for_customer_full_name'}.should route_to(
        :controller => 'customers', :action => 'auto_complete_for_customer_full_name')
    end
  end
  specify 'enable/disable admin' do
    [:get, :post].each do |action|
      {action => '/session/temporarily_disable_admin'}.should route_to(
        (:controller => 'sessions', :action => 'temporarily_disable_admin'))
      {action => '/customers/reenable_admin'}.should route_to(
          (:controller => 'sessions', :action => 'reenable_admin'))
    end
  end
  specify 'lookup customer' do
    [:get, :post].each do |method|
      {method => '/customers/lookup'}.should route_to (:controller => 'customers', :action => 'lookup')
    end
  end
end
