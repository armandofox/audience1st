ActionController::Routing::Routes.draw do |map|
  map.resources :bulk_downloads
  map.resources :account_codes
  map.resources(:imports,
    :except => [:show] ,
    :member => {:download_invalid => :get},
    :collection => {:help => :get})
  
  map.resources :labels

  map.resources(:customers,
    :except => :destroy,
    :collection => {
      :merge => :get,
      :user_create => :post,
      :finalize_merge => :post,
      :search => :get,
      :list_duplicate => :get,
      :forgot_password => [:get, :post] # dual-purpose action
    },
    :member => {
      :change_password_for => [:get, :post], # dual-purpose action
      :change_secret_question => [:get, :post] # dual-purpose action
    })  do  |customer|

    customer.resources(:vouchers,
      :only => [:index, :new, :create],
      :member => {
        :update_comment => :post,
        :reserve => :get,
        :confirm_reservation => :post,
        :cancel_reservation => :post,
        :cancel_prepaid => :post,
      },
      :collection => {
        :transfer_multiple => :post,
        :confirm_multiple => :post,
        :cancel_multiple => :post,
      })
    
  end
      
  # RSS

  map.connect '/info/ticket_rss', :controller => 'info', :action => 'ticket_rss', :conditions => {:method => :get}

  # AJAX responders
  map.update_shows '/ajax/update_shows', :controller => 'vouchers', :action => 'update_shows'
  map.customer_autocomplete '/ajax/customer_autocomplete', :controller => 'customers', :action => 'auto_complete_for_customer_full_name'
  map.customer_lookup '/ajax/customer_lookup', :controller => 'customers', :action => 'lookup'
  map.mark_fulfilled '/ajax/mark_fulfilled', :controller => 'reports', :action => 'mark_fulfilled'
  map.create_sublist '/ajax/create_sublist', :controller => 'reports', :action => 'create_sublist'

  # shows
  map.resources :shows, :except => [:show] do |show|
    show.resources :showdates, :except => [:index]
  end
  map.resources :valid_vouchers, :except => [:index]
  map.resources :vouchertypes, :member => { :clone => :get }
    
  # database txns
  map.connect '/txns', :controller => 'txn', :action => 'index', :conditions => {:method => :get}


  # reports
  map.reports '/reports', :controller => 'reports', :action => 'index'
  %w(do_report run_special_report advance_sales transaction_details_report accounting_report retail show_special_report unfulfilled_orders).each do |report_name|
    map.connect "/reports/#{report_name}", :controller => 'reports', :action => report_name
  end
  # reports that consume :id
  %w(showdate_sales subscriber_details).each do |report_name|
    map.connect "/reports/#{report_name}/:id", :controller => 'reports', :action => report_name
  end

  # customer-facing purchase pages
  #  Entry into purchase flow:
  #    -  via :index, :subscribe, or :donate_to_fund - customer ID optional but guaranteed to be set
  #       on all subsequent pages in that flow
  #    -  via :donate (quick donation) - no customer ID needed nor set; the only other page in
  #       the flow is the POST back to this same URL

  map.store('/store/:customer_id', :controller => 'store', :action => 'index',
    :customer_id => nil,
    :conditions => {:method => :get})

  map.store_subscribe( '/subscribe/:customer_id', :controller => 'store', :action => 'subscribe',
  :customer_id => nil,
  :conditions => {:method => :get})
  
  map.donate_to_fund('/donate_to_fund/:id/:customer_id',
  :customer_id => nil,
  :controller => 'store', :action => 'donate_to_fund', :conditions => {:method => :get})

  # subsequent actions in the above flow require a customer_id in the URL:

  map.process_cart("/store/:customer_id/process_cart",
    :controller => 'store', :action => 'process_cart',
    :conditions => {:method => :post})
  # process_cart redirects to either shipping_address (if a gift) or checkout (if not) a gift:

  map.shipping_address '/store/:customer_id/shipping_address', :controller => 'store', :action => 'shipping_address'

  # checkout requires you to be logged in:

  map.checkout "/store/:customer_id/checkout", :controller => 'store', :action => 'checkout', :conditions => {:method => :get}
  
  map.place_order '/store/:customer_id/place_order', :controller => 'store', :action => 'place_order',
  :conditions => {:method => :post}

  # quick-donation neither requires nor sets customer-id:

  map.quick_donate '/donate', :controller => 'store', :action => 'donate', :as => 'quick_donate'

  # donations management

  map.resources(:donations, :only  => [:index, :new, :create, :update])
  
  # config options

  map.options '/options', :controller => 'options', :action => 'options'

  # walkup sales

  map.walkup_sales('/box_office/walkup/:id',
    :id => nil,
    :controller => 'box_office', :action => 'walkup',
    :conditions => {:method => :get})
  map.door_list '/box_office/:id/door_list', :controller => 'box_office', :action => 'door_list', :conditions => {:method => :get}
  map.checkin  '/box_office/:id/checkin', :controller => 'box_office', :action => 'checkin', :conditions => {:method => :get}
  map.walkup_report '/box_office/:id/walkup_report', :controller => 'box_office', :action => 'walkup_report', :conditions => {:method => :get}
  %w(do_walkup_sale modify_walkup_vouchers).each do |action|
    map.connect "/box_office/#{action}", :controller => 'box_office', :action => action, :conditions => {:method => :post}
  end
  map.connect '/box_office/mark_checked_in', :controller => 'box_office', :action => 'mark_checked_in', :conditions => {:method => :post}


  map.resource(:session,
    :only => [:new, :create],
    :collection => {
      :new_from_secret => :get,
      :create_from_secret => :post,
      :temporarily_disable_admin => :get, # should be in separate controller
      :reenable_admin => :get, # should be in separate controller
    })
  # special shortcuts
  map.login '/login', :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'


  # Routes for viewing and refunding orders
  map.resources(:orders, :only => [:index, :show, :update])

  map.root :controller => 'customers', :action => 'show'
 
end
