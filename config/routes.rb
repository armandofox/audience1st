ActionController::Routing::Routes.draw do |map|
  map.resources :donation_funds

  # just enough RESTful routes for restful_authentication to work
  # map.resources :customers
  map.connect '/customers/:id/show', :controller => 'customers', :action => 'welcome'
  
  # special shortcuts
  map.connect 'subscribe', :controller => 'store', :action => 'subscribe'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.resource :session

  
  #map.connect ':controller/:action/:id.:format'
  map.connect '', {:controller => 'customers', :action => 'welcome'}
  map.root :controller => 'customers', :action => 'welcome'
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id', :defaults => {:controller => :customers, :action => :welcome}
  map.connect '*path', {:controller => 'customers', :action => 'welcome'}
 
end
