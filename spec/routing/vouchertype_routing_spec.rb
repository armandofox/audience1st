require 'spec_helper'

describe 'vouchertype routes', :type => :routing do
  specify 'for cloning' do
    {:get => '/vouchertypes/clone/44'}.should route_to(:controller => 'vouchertypes', :action => 'merge', :id => 44)
  end
end
    
