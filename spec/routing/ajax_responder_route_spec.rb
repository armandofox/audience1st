require 'rails_helper'

describe "AJAX responder routes", :type => :routing do
  specify 'autocomplete' do
    expect({:get => '/ajax/customer_autocomplete'}).to route_to(
      :controller => 'customers', :action => 'auto_complete_for_customer')
  end
end
