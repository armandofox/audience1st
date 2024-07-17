Rails.application.routes.draw do

  scope :format => false do

    root :to => 'customers#show'

    resources :account_codes, :except => :show
    resources :ticket_sales_imports, :except => [:new]
    resources :labels, :only => [:index, :create, :update, :destroy]
    resources :seatmaps, :except => [:new] 
    resources :seating_zones, :only => [:index, :create, :destroy]

    resources :customers, :except => :destroy do
      collection do
        get  :merge
        get  :guest_checkout
        get  :admin_new
        post :user_create
        post :guest_checkout_create
        post :finalize_merge
        get  :search
        get  :list_duplicate
        get  :forgot_password
        post :forgot_password
        get  :reset_token
      end
      member do
        get  :change_password_for
        post :change_password_for
        get  :change_secret_question
        post :change_secret_question
      end
      resources :donations, :only => [:new, :create]
      resources :vouchers, :only => [:index, :new, :create] do
        member do
          put :update_comment
        end
        collection do
          post :transfer_multiple
          post :confirm_multiple
          post :cancel_multiple
        end
      end
    end

    # list all donations management

    resources :donations, :only  => [:index, :update] do
      member do
        post :update_comment_for
      end
    end

    # RSS

    get '/ics/showdates.ics'          => 'info#showdates'
    get '/rss/showdates.rss'          => 'info#ticket_rss', :defaults => { :format => 'rss' }
    get '/rss/availability.rss'       => 'info#availability', :defaults => { :format => 'rss' }

    # AJAX responders
    get '/ajax/update_shows'          => 'reservations#update_shows', :as => 'update_shows'
    get '/ajax/customer_autocomplete' => 'customers#auto_complete_for_customer', :as => 'customer_autocomplete'
    get '/ajax/customer_lookup'       => 'customers#lookup', :as => 'customer_lookup'

    post '/ajax/mark_fulfilled'       => 'reports#mark_fulfilled', :as => 'mark_fulfilled'
    get '/ajax/create_sublist'        => 'reports#create_sublist', :as => 'create_sublist'

    # AJAX responders for seatmap functions
    get '/ajax/seatmap/:id'           => 'seatmaps#seatmap'
    get '/ajax/house_seats_seatmap/:id' => 'seatmaps#house_seats_seatmap'
    get '/ajax/raw_seatmap/:id'       => 'seatmaps#raw_seatmap'
    post '/ajax/import_assign_seats'  => 'seatmaps#assign_seats', :as => 'import_assign_seats'

    # shows
    resources :shows, :except => [:show] do
      resources :showdates, :except => [:index]
    end
    
    resources :valid_vouchers, :except => [:index]
    resources :vouchertypes do
      member do
        get :clone
      end
    end

    # database txns
    resources :txns, :only => [:index]

    # reports
    resources :reports, :only => [:index] do
      member do
        get :showdate_sales
      end
      collection do
        get :run_special
        get :subscriber_details
        get :attendance
        get :advance_sales
        get :do_report
        get :revenue_by_payment_method
        get :retail
        get :unfulfilled_orders
      end
    end

    # customer-facing purchase pages
    #  Entry into purchase flow:
    #    -  via :index, :subscribe, or :donate_to_fund - customer ID optional but guaranteed to be set
    #       on all subsequent pages in that flow
    #    -  via :donate (quick donation) - no customer ID needed nor set; the only other page in
    #       the flow is the POST back to this same URL

    get '/store/(:customer_id)' => 'store#index', :defaults => {:customer_id => nil}, :as => 'store'
    get '/subscribe/(:customer_id)' => 'store#subscribe', :defaults => {:customer_id => nil}, :as => 'store_subscribe'
    get '/donate_to_fund/(:id)/(:customer_id)', :defaults => {:customer_id => nil}, to: 'store#donate_to_fund_redirect'
    get '/store/cancel' => 'store#cancel', :as => 'store_cancel'

    # subsequent actions in the above flow require a customer_id in the URL:

    post '/store/:customer_id/process_cart' => 'store#process_cart', :as => 'process_cart'
    # process_cart redirects to either shipping_address (if a gift) or checkout (if not) a gift:
    match '/store/:customer_id/shipping_address' => 'store#shipping_address', :via => [:get,:post], :as => 'shipping_address'

    # checkout requires you to be logged in:
    get '/store/:customer_id/select_seats' => 'store#select_seats', :as => 'select_seats'
    get '/store/:customer_id/checkout' => 'store#checkout', :as => 'checkout'

    post '/store/:customer_id/place_order' => 'store#place_order', :as => 'place_order'

    # quick-donation neither requires nor sets customer-id:

    get '/donate/(:customer_id)' => 'store#donate', :as => 'quick_donate'
    post '/process_donation/(:customer_id)' => 'store#process_donation', :as => 'process_donation'

    # config options

    resources :options, :only => [:index, :update] do
      collection do
        get :download_email_template
        get :swipe_test
        post :email_test
      end
    end

    # walkup sales

    resources :walkup_sales, :only => [:show, :create, :update] do
      member do
        get :report
      end
    end

    resources :checkins, :only => [:show, :update] do
      member do
        get :door_list
        get :seatmap
        get :walkup_subscriber
        post :walkup_subscriber_confirm
      end
    end

    resource :session, :only => [:new, :create] do
      collection do
        get  :new_from_secret
        post :create_from_secret
        get  :temporarily_disable_admin # should be in separate controller
        get  :reenable_admin # should be in separate controller
      end
    end

    # special shortcuts

    get '/login' => 'sessions#new', :as => 'login'
    match '/logout' => 'sessions#destroy', :as => 'logout', :via => [:get, :post]

    # Routes for viewing and refunding orders
    resources :orders, :only => [:index, :show, :update]
  end
end
