module AuthenticatedSystem
  protected

  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    !!current_user
  end

  # Store the given user id in the session.
  def current_user=(new_user)
    session[:cid] = new_user ? new_user.id : nil
    @current_user = new_user || false
    logger.info "**** setting current user to #{@current_user}"
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    unless @current_user == false # false means don't attempt auto login
      @current_user ||= (login_from_session || login_from_cookie)
      if @current_user && !session[:admin_id] && (session[:admin_id] != false)
        logger.info "Checking whether to enable admin on #{@current_user}"
        possibly_enable_admin(@current_user)
      end
    end
    @current_user
  end

  def new_session?
    # returns true the FIRST time it's called on a session.  Used for
    # displaying login-time messages, etc.
    retval = !session[:exists]
    session[:exists] = true
    retval
  end
  
  def act_on_behalf_of(new_user)
    if new_user
      session[:cid] = new_user.id
      @current_user = new_user
    end
  end

  def acting_on_own_behalf
    (!session[:admin_id] && !session[:can_restore_admin]) || 
      (session[:admin_id] == session[:cid])
  end

  def logged_in_user
    session[:admin_id] ? current_admin : current_user
  end

  def logged_in_id
    # Return the "effective logged-in ID" for audit purposes (ie to track
    # who did what).
    # if NO ADMIN is logged in, this is the logged-in customer's ID, or the
    #   id of the 'nobody' fake customer if not set.
    # if an admin IS logged in, it's that admin's ID.
    return (session[:admin_id] || session[:cid] || Customer.nobody_id).to_i
  end


  
  # current_admin is called from controller actions filtered by is_logged_in,
  # so there might in fact be NO admin logged in.
  # So it returns customer record of current admin, if one is logged in;
  # otherwise returns a 'generic' customer with no admin privileges but on
  # which it is safe to call instance methods of Customer.
  def current_admin
    (!session[:admin_id] || session[:admin_id].to_i.zero?) ?
    Customer.generic_customer :
      (Customer.find_by_id(session[:admin_id]) || Customer.generic_customer)
  end

  # enable admin ID in session if this user is in fact an admin
  def possibly_enable_admin(c = Customer.generic_customer)
    return nil unless c
    return nil if session[:admin_id] == false # don't try to enable automatically
    session[:admin_id] = false
    if c.is_staff # least privilege level that allows seeing other customer accts
      (flash[:notice] ||= '') << 'Logged in as Administrator ' + c.first_name
      session[:admin_id] = c.id
      session.delete(:can_restore_admin)
    end
    c
  end

  def disable_admin
    session[:can_restore_admin] = session[:admin_id]
    session[:admin_id] = false
  end

    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    #
    def authorized?(action = action_name, resource = nil)
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          set_return_to
          redirect_to new_session_path
        end
        # format.any doesn't work in rails version < http://dev.rubyonrails.org/changeset/8987
        # Add any other API formats here.  (Some browsers, notably IE6, send Accept: */* and trigger 
        # the 'format.any' block incorrectly. See http://bit.ly/ie6_borken or http://bit.ly/ie6_borken2
        # for a workaround.)
        format.any(:json, :xml) do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the action to return to, or URI of the current request if no action given.
    # We can return to this location by calling #redirect_to_stored.
    def set_return_to(hsh=nil)
      session[:return_to] = hsh || request.request_uri
      true
    end

    def stored_action ; session[:return_to] || {:action => :index} ; end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.  Set an appropriately modified
    #   after_filter :store_location, :only => [:index, :new, :show, :edit]
    # for any controller you want to be bounce-backable.
    def redirect_to_stored(params={})
      if session[:return_to]
        redirect_to session[:return_to]
      else
        redirect_to :controller => 'customers', :action => 'welcome'
      end
      session[:return_to] = nil
      true
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :authorized? if base.respond_to? :helper_method
    end

    #
    # Login
    #

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    def login_from_session
      self.current_user = Customer.find_by_id(session[:cid]) if session[:cid]
    end

    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |email, password|
        self.current_user = Customer.authenticate(email, password)
      end
    end

    # login via Facebook Connect info
  if USE_FACEBOOK
    def login_from_facebook
      if facebook_session
        logger.info("login_from_facebook: Trying to set current user from FB id #{facebook_session.user}") 
        self.current_user = Customer.find_by_fb_user(facebook_session.user)
      end
    end
  else
    def login_from_facebook ; false ; end
  end
    #
    # Logout
    #

    # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
    # for the paranoid: we _should_ be storing user_token = hash(cookie_token, request IP)
    def login_from_cookie
      user = cookies[:auth_token] && Customer.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        self.current_user = user
        handle_remember_cookie! false # freshen cookie token (keeping date)
        self.current_user
      end
    end

    # This is ususally what you want; resetting the session willy-nilly wreaks
    # havoc with forgery protection, and is only strictly necessary on login.
    # However, **all session state variables should be unset here**.
    def logout_keeping_session!
      # Kill server-side auth cookie
      @current_user.forget_me if @current_user.is_a? Customer
      @current_user = false     # not logged in, and don't do it for me
      session[:cid] = nil
      session[:admin_id] = nil
      reset_shopping unless @gCheckoutInProgress
      kill_remember_cookie!     # Kill client-side auth cookie
    end

    # The session should only be reset at the tail end of a form POST --
    # otherwise the request forgery protection fails. It's only really necessary
    # when you cross quarantine (logged-out to logged-in).
    def logout_killing_session!
      logout_keeping_session!
      reset_session
    end
    
    #
    # Remember_me Tokens
    #
    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    def valid_remember_cookie?
      return nil unless @current_user
      (@current_user.remember_token?) && 
        (cookies[:auth_token] == @current_user.remember_token)
    end
    
    # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie!(new_cookie_flag)
      return unless @current_user
      case
      when valid_remember_cookie? then @current_user.refresh_token # keeping same expiry date
      when new_cookie_flag        then @current_user.remember_me 
      else                             @current_user.forget_me
      end
      send_remember_cookie!
    end
  
    def kill_remember_cookie!
      cookies.delete :auth_token
    end
    
    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @current_user.remember_token,
        :expires => @current_user.remember_token_expires_at }
    end

end
