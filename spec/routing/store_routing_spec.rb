require 'spec_helper'

describe 'store', :type => :routing do
  describe 'index route' do
    before :each do
      @r = {:controller => 'store', :action => 'index'}
      @c=mock_model(Customer)
    end
    specify 'bare' do
      {:get => '/store'}.should route_to @r
    end
    specify 'with customer' do
      { :get => "/store/#{@c.id}" }.should route_to(@r.merge(:customer_id => @c.id.to_s))
    end
    specify 'with promo only' do
      { :get => '/store?promo_code=blah' }.should route_to(@r.merge(:promo_code => 'blah'))
    end
    specify 'with promo and customer' do
      { :get => "/store/#{@c.id}?promo_code=blah" }.should route_to(
        @r.merge(:customer_id => @c.id.to_s, :promo_code => 'blah'))
    end
  end
end
