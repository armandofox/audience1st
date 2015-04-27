ActionController::Routing::Routes.draw do |map|
  map.resources :bulk_downloads
  map.resources :account_codes
  map.resources :imports
  map.connect '/imports/download_invalid/:id', :controller => 'imports', :action => 'download_invalid'
  map.connect '/imports/help', :controller => 'imports', :action => 'help'
  map.resources :labels
  

  map.resources(:customers,
    :except => :destroy,
    :new => {:user_create => :post},
    :collection => {
      :temporarily_disable_admin => [:get,:post], # should be in separate controller
      :reenable_admin => [:get,:post], # should be in separate controller
      :auto_complete_for_customer_full_name => [:get,:post], # should be in separate controller
      :merge => :get,
      :finalize_merge => :post,
      :search => :get,
      :lookup => [:get,:post],    # should be obsoleted
      :list_duplicate => :get,
      :forgot_password => [:get, :post] # dual-purpose action
    },
    :member => {
      :change_password_for => [:get, :post], # dual-purpose action
      :change_secret_question => [:get, :post] # dual-purpose action
    })
      
  # RSS

  map.connect '/info/ticket_rss', :controller => 'info', :action => 'ticket_rss', :conditions => {:method => :get}
  

  # shows
  map.resources :shows, :except => [:show]
  map.resources :showdates, :except => [:index]
  map.resources :valid_vouchers, :except => [:index]
  map.resources :vouchertypes
  map.connect '/vouchertypes/clone/:id', :controller => 'vouchertypes', :action => 'clone', :conditions => {:method => :get}

  # vouchers
  map.connect '/vouchers/update_shows', :controller => 'vouchers', :action => 'update_shows'
  map.customer_add_voucher '/customer/:id/addvoucher', :controller => 'vouchers', :action => 'addvoucher', :conditions => {:method => :get}
  map.customer_process_add_voucher '/customer/:id/process_addvoucher', :controller => 'vouchers', :action => 'process_addvoucher', :conditions => {:method => :post}
  
  # with :id
  map.connect '/vouchers/reserve/:id', :controller => 'vouchers', :action => 'reserve', :conditions => {:method => :get}
  %w(update_comment confirm_multiple confirm_reservation cancel_prepaid cancel_multiple cancel_reservation).each do |action|
    map.connect "/vouchers/#{action}", :controller => 'vouchers', :action => action, :conditions => {:method => :post}
  end

  # database txns
  map.connect '/txns', :controller => 'txn', :action => 'index', :conditions => {:method => :get}

  # customer visits
  map.resources 'visits'
  map.customer_visits '/customer/:id/visits', :controller => 'visits', :action => 'index'
  map.connect '/visits/list_by_prospector', :controller => 'visits', :action => 'list_by_prospector', :conditions => {:method => :get}

  # reports
  map.reports '/reports', :controller => 'reports', :action => 'index'
  %w(do_report run_special_report advance_sales transaction_details_report accounting_report retail show_special_report unfulfilled_orders).each do |report_name|
    map.connect "/reports/#{report_name}", :controller => 'reports', :action => report_name
  end
  # reports that consume :id
  %w(showdate_sales subscriber_details).each do |report_name|
    map.connect "/reports/#{report_name}/:id", :controller => 'reports', :action => report_name
  end
  # update actions
  %w(mark_fulfilled create_sublist).each do |action|
    map.connect "/reports/#{action}", :controller => 'reports', :action => action, :conditions => {:method => :post}
  end

  # customer-facing purchase pages
  #  Entry into purchase flow:
  #    -  via :index, :subscribe, or :donate_to_fund - customer ID optional but guaranteed to be set
  #       on all subsequent pages in that flow
  #    -  via :donate (quick donation) - no customer ID needed nor set; the only other page in
  #       the flow is the POST back to this same URL

  map.store     '/store/:customer_id', :controller => 'store', :action => 'index',
  :customer_id => nil,
  :conditions => {:method => :get}

  map.store_subscribe '/subscribe/:customer_id', :controller => 'store', :action => 'subscribe',
  :customer_id => nil,
  :conditions => {:method => :get}
  
  map.donate_to_fund '/store/donate_to_fund/:id/:customer_id',
  :customer_id => nil,
  :controller => 'store', :action => 'donate_to_fund', :conditions => {:method => :get}

  # subsequent actions in the above flow require a customer_id:

  %w(shipping_address checkout edit_billing_address).each do |action|
    map.send(action, "/store/:customer_id/#{action}", :controller => 'store', :action => action)
  end

  %w(process_cart set_shipping_address).each do |action|
    map.send(action, "/store/:customer_id/#{action}", :controller => 'store', :action => action, :conditions => {:method => :post})
  end
  
  # quick-donation neither requires nor sets customer-id:

  map.quick_donate '/donate', :controller => 'store', :action => 'donate'

  # place_order doesn't require customer_id because a valid order contains both buyer and recipient info:

  map.place_order '/store/place_order', :controller => 'store', :action => 'place_order',
  :conditions => {:method => :post}

  %w(show_changed showdate_changed).each do |action|
    map.send(action, "/#{action}", :controller => 'store', :action => action)
  end


  # donations management

  map.donations '/donations', :controller => 'donations', :action => 'index', :conditions => {:method => :get}
  map.connect '/donations/mark_ltr_sent',  :controller => 'donations', :action => 'mark_ltr_sent', :conditions => {:method => :get}
  
  # config options

  map.options '/options', :controller => 'options', :action => 'edit', :conditions => {:method => :get}
  map.connect '/options/update', :controller => 'options', :action => 'update', :conditions => {:method => :put}

  # walkup sales

  map.walkup_sales '/box_office/walkup/:id', :controller => 'box_office', :action => 'walkup', :conditions => {:method => :get}
  map.walkup_default '/box_office/walkup', :controller => 'box_office', :action => 'walkup', :conditions => {:method => :get}
  map.connect "/box_office/change_showdate", :controller => 'box_office', :action => 'change_showdate'
  map.door_list '/box_office/:id/door_list', :controller => 'box_office', :action => 'door_list', :conditions => {:method => :get}
  map.checkin  '/box_office/:id/checkin', :controller => 'box_office', :action => 'checkin', :conditions => {:method => :get}
  map.walkup_report '/box_office/:id/walkup_report', :controller => 'box_office', :action => 'walkup_report', :conditions => {:method => :get}
  %w(do_walkup_sale modify_walkup_vouchers).each do |action|
    map.connect "/box_office/#{action}", :controller => 'box_office', :action => action, :conditions => {:method => :post}
  end
  map.connect '/box_office/mark_checked_in', :controller => 'box_office', :action => 'mark_checked_in', :conditions => {:method => :post}


  map.resource(:session,
    :only => [:new, :create],
    :new => {:secret_question_create => :post},
    :collection => {
      :login_with_secret => :get
    })
  # special shortcuts
  map.login '/login', :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  #map.secret_question '/login_with_secret', :controller => 'sessions', :action => 'new_from_secret_question',:conditions => {:method => :get}
  #map.connect '/sessions/create_from_secret_question', :controller => 'sessions', :action => 'create_from_secret_question', :conditions => {:method => :post}
  map.change_user '/not_me', :controller => 'sessions', :action => 'not_me'



  # Routes for viewing and refunding orders
  map.order '/orders/:id', :controller => 'orders', :action => 'show', :conditions => {:method => :get}
  map.connect '/orders/refund/:id', :controller => 'orders', :action => 'refund', :conditions => {:method => :post}
  map.customer_orders '/orders/by_customer/:id', :controller => 'orders', :action => 'by_customer'

  map.root :controller => 'customers', :action => 'home'
 
end
