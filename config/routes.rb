ActionController::Routing::Routes.draw do |map|
  map.resources :bulk_downloads
  map.resources :account_codes
  map.resources :imports
  map.connect '/imports/download_invalid/:id', :controller => 'imports', :action => 'download_invalid'
  map.connect '/imports/help', :controller => 'imports', :action => 'help'
  map.resources :labels
  
  map.welcome  '/customers/welcome', :controller => 'customers', :action => 'welcome', :conditions => {:method => :get}
  map.connect '/customers/:id/show', :controller => 'customers', :action => 'welcome', :conditions => {:method => :get}
  %w(new temporarily_disable_admin reenable_admin auto_complete_for_customer_full_name).each do |action|
    map.connect "/customers/#{action}", :controller => 'customers', :action => action, :conditions => {:method => :get}
  end
  map.connect '/customers/create', :controller => 'customers', :action => 'create', :conditions => {:method => :post}
  map.connect '/customers/user_create', :controller => 'customers', :action => 'user_create', :conditions => {:method => :post}
  map.connect '/customers/edit/:id', :controller => 'customers', :action => 'edit', :conditions => {:method => :get}
  map.connect '/customers/switch_to/:id', :controller => 'customers', :action => 'switch_to', :conditions => {:method => :get}
  map.connect '/customers/update/:id', :controller => 'customers', :action => 'update', :conditions => {:method => :post}
  map.connect '/customers/change_password', :controller => 'customers', :action => 'change_password'
  map.forgot_password '/customers/forgot_password', :controller => 'customers', :action => 'forgot_password'
  map.connect '/customers/change_secret_question', :controller => 'customers', :action => 'change_secret_question'
  map.connect '/customers/list', :controller => 'customers', :action => 'index', :conditions => {:method => :get}
  map.connect '/customers/list_duplicates', :controller => 'customers', :action => 'list_duplicates', :conditions => {:method => :get}
  map.connect '/customers/merge', :controller => 'customers', :action => 'merge', :conditions => {:method => :get}
  map.connect '/customers/finalize_merge', :controller => 'customers', :action => 'finalize_merge', :conditions => {:method => :post}
  %w(search lookup).each do |action|
    map.connect "/customers/#{action}", :controller => 'customers', :action => action, :conditions => {:method => :get}
  end

  # shows
  map.resources :shows, :except => [:show]
  map.resources :showdates, :except => [:index]
  map.resources :valid_vouchers, :except => [:index]
  map.resources :vouchertypes
  map.connect '/vouchertypes/clone/:id', :controller => 'vouchertypes', :action => 'clone', :conditions => {:method => :get}

  # vouchers
  %w(update_shows addvoucher).each do |action|
    map.connect "/vouchers/#{action}", :controller => 'vouchers', :action => action, :conditions => {:method => :get}
  end
  # with :id
  map.connect '/vouchers/reserve/:id', :controller => 'vouchers', :action => 'reserve', :conditions => {:method => :get}
  %w(process_addvoucher update_comment confirm_multiple confirm_reservation cancel_prepaid cancel_multiple cancel_reservation).each do |action|
    map.connect "/vouchers/#{action}", :controller => 'vouchers', :action => action, :conditions => {:method => :post}
  end

  # database txns
  map.connect '/txns', :controller => 'txn', :action => 'index', :conditions => {:method => :get}

  # customer visits
  map.resources 'visits'
  map.connect '/visits/list_by_prospector', :controller => 'visits', :action => 'list_by_prospector', :conditions => {:method => :get}

  # reports
  map.connect '/reports', :controller => 'reports', :action => 'index'
  %w(do_report run_special_report advance_sales transaction_details_report accounting_report retail show_special_report unfulfilled_orders).each do |report_name|
    map.connect "/reports/#{report_name}", :controller => 'reports', :action => report_name, :conditions => {:method => :get}
  end
  # reports that consume :id
  %w(showdate_sales subscriber_details).each do |report_name|
    map.connect "/reports/#{report_name}/:id", :controller => 'reports', :action => report_name, :conditions => {:method => :get}
  end
  # update actions
  %w(mark_fulfilled create_sublist).each do |action|
    map.connect "/reports/#{action}", :controller => 'reports', :action => action, :conditions => {:method => :post}
  end

  # customer-facing purchase pages

  %w(index special subscribe shipping_address checkout edit_billing_address show_changed showdate_changed).each do |action|
    map.connect "/store/#{action}", :controller => 'store', :action => action, :conditions => {:method => :get}
  end

  %w(process_cart set_shipping_address place_order).each do |action|
    map.connect "/store/#{action}", :controller => 'store', :action => action, :conditions => {:method => :post}
  end
  map.donate_to_fund '/store/donate_to_fund/:id', :controller => 'store', :action => 'donate_to_fund', :conditions => {:method => :get}
  map.quick_donate '/donate', :controller => 'store', :action => 'donate', :conditions => {:method => :get}
  map.connect '/process_quick_donation', :controller => 'store', :action => 'process_quick_donation', :conditions => {:method => :post}

  # donations management

  map.connect '/donations', :controller => 'donations', :action => 'index', :conditions => {:method => :get}
  map.connect '/donations/mark_ltr_sent',  :controller => 'donations', :action => 'mark_ltr_sent', :conditions => {:method => :get}
  
  # config options

  map.connect '/options', :controller => 'options', :action => 'edit', :conditions => {:method => :get}
  map.connect '/options/update', :controller => 'options', :action => 'update', :conditions => {:method => :put}

  # walkup sales

  map.connect '/box_office/walkup/:id', :controller => 'box_office', :action => 'walkup', :conditions => {:method => :get}
  map.connect '/box_office/walkup', :controller => 'box_office', :action => 'walkup', :conditions => {:method => :get}
  %w(change_showdate).each do |action|
    map.connect "/box_office/#{action}", :controller => 'box_office', :action => action, :conditions => {:method => :get}
  end
  %w(checkin walkup door_list walkup_report).each do |action|
    map.connect "/box_office/#{action}/:id", :controller => 'box_office', :action => action, :conditions => {:method => :get}    
  end
  %w(do_walkup_sale modify_walkup_vouchers).each do |action|
    map.connect "/box_office/#{action}", :controller => 'box_office', :action => action, :conditions => {:method => :post}
  end
  map.connect '/box_office/mark_checked_in', :controller => 'box_office', :action => 'mark_checked_in', :conditions => {:method => :post}


  # special shortcuts
  map.login '/login', :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.secret_question '/login_with_secret', :controller => 'sessions', :action => 'new_from_secret_question',:conditions => {:method => :get}
  map.connect '/sessions/create_from_secret_question', :controller => 'sessions', :action => 'create_from_secret_question', :conditions => {:method => :post}
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.change_user '/not_me', :controller => 'sessions', :action => 'not_me'
  map.store '/store', :controller => 'store', :action => 'index', :conditions => {:method => :get}

  map.resource :session # other session actions

  map.connect 'subscribe', :controller => 'store', :action => 'subscribe', :conditions => {:method => :get}

  # Routes for viewing and refunding orders
  map.order '/orders/:id', :controller => 'orders', :action => 'show', :conditions => {:method => :get}
  map.connect '/orders/refund/:id', :controller => 'orders', :action => 'refund', :conditions => {:method => :post}
  map.connect '/orders/by_customer/:id', :controller => 'orders', :action => 'by_customer'

  #map.connect '*anything', :controller => 'customers', :action => 'welcome'
  map.root :controller => 'customers', :action => 'welcome'
 
end
