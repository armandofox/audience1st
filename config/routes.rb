ActionController::Routing::Routes.draw do |map|
  map.resources :donation_funds
  map.resource :session

  # just enough RESTful routes for restful_authentication to work
  # map.resources :customers
  map.connect '/customers/:id/show', :controller => 'customers', :action => 'welcome'
  
  # special shortcuts
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.connect 'subscribe', :controller => 'store', :action => 'subscribe'
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect '*anything', :controller => 'customers', :action => 'welcome'
  map.connect '', :controller => 'customers', :action => 'welcome'
  map.root :controller => 'customers', :action => 'welcome'
 
end
