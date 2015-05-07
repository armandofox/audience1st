require 'spec_helper'

describe 'vouchertype routes', :type => :routing do
  specify 'for cloning' do
    {:get => '/vouchertypes/44/clone'}.should route_to(:controller => 'vouchertypes', :action => 'clone', :id => 44)
  end
end
    
