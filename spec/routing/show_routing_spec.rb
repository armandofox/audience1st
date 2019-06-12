require 'rails_helper'

describe 'Show routing', :type => :routing do
  before :all do ; @r = {:controller => 'shows'} ; end
  it 'lists shows by season' do
    expect({:get => '/shows?season=2013'}).to route_to @r.merge(:action => 'index', :season => '2013')
  end
  it 'destroys' do
    expect({:delete => '/shows/33'}).to route_to @r.merge(:action => 'destroy', :id => '33')
  end
end
