require 'spec_helper'

describe 'Showdate routing', :type => :routing do
  before :all do ; @r = {:controller => 'showdates'} ; end
  it 'for new showdate with show ID' do
    {:get => '/showdates/new?show_id=99'}.should route_to @r.merge(:action => 'new', :show_id => '99')
  end
end
