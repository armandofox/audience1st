require 'spec_helper'

describe "AJAX responder routes", :type => :routing do
  specify 'autocomplete' do
    [:get, :post].each do |action|
      {action => '/ajax/customer_autocomplete'}.should route_to(
        :controller => 'customers', :action => 'auto_complete_for_customer_full_name')
    end
  end
  specify 'lookup customer' do
    [:get, :post].each do |method|
      {method => '/ajax/customer_lookup'}.should route_to (:controller => 'customers', :action => 'lookup')
    end
  end
end
