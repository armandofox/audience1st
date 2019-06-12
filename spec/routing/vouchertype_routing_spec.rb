require 'rails_helper'

describe 'vouchertype routes', :type => :routing do
  specify 'for cloning' do
    expect({:get => '/vouchertypes/44/clone'}).to route_to(:controller => 'vouchertypes', :action => 'clone', :id => '44')
  end
end
    
