module AuthenticatedSystem
  protected

  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    !!current_user
  end

  # Store the given user id in the session.
  def current_user=(new_user)
    if new_user
      session[:cid] = new_user.id
      @current_user = new_user
      session[:admin_id] = new_user.id if new_user.is_staff
      logger.info "**** setting current user to #{@current_user}"
    else
      session[:cid] = session[:admin_id] = nil
      @current_user = false
    end
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    unless @current_user == false # false means don't attempt auto login
      @current_user ||= (login_from_session || login_from_cookie)
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
    Customer.find_by_id(session[:admin_id]) || Customer.generic_customer
  end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in? if base.respond_to? :helper_method
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
