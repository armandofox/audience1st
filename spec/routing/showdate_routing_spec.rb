require 'rails_helper'

describe 'Showdate routing', :type => :routing do
  before :all do ; @r = {:controller => 'showdates'} ; end
  it 'for new showdate with show ID' do
    {:get => '/shows/99/showdates/new'}.should route_to @r.merge(:action => 'new', :show_id => '99')
  end
end
