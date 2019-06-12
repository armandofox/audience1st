require 'rails_helper'

describe 'store', :type => :routing do
  describe 'index route' do
    before :each do
      @r = {:controller => 'store', :action => 'index', :customer_id => nil}
      @c=mock_model(Customer)
    end
    specify 'bare' do
      expect({:get => '/store'}).to route_to @r
    end
    specify 'with customer' do
      expect({ :get => "/store/#{@c.id}" }).to route_to(@r.merge(:customer_id => @c.id.to_s))
    end
    specify 'with promo only' do
      expect({ :get => '/store?promo_code=blah' }).to route_to(@r.merge(:promo_code => 'blah'))
    end
    specify 'with promo and customer' do
      expect({ :get => "/store/#{@c.id}?promo_code=blah" }).to route_to(
        @r.merge(:customer_id => @c.id.to_s, :promo_code => 'blah'))
    end
  end
end
