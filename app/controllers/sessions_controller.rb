# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  ssl_required :new, :create
  ssl_allowed :destroy

  # render new.rhtml
  def new
    redirect_to :controller => 'customers', :action => 'welcome' if logged_in?
    @page_title = "Login or Create Account"
    if (@gCheckoutInProgress)
      @cart = find_cart
    end
    @remember_me = true
    @email ||= params[:email]
  end

  def create
    logout_keeping_session!
    @user = Customer.authenticate(params[:email], params[:password])
    if (@user.nil? || !@user.errors.empty?)
      note_failed_signin
      @email       = params[:email]
      @remember_me = params[:remember_me]
      render :action => 'new'
    else
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = @user
      # if user is an admin, enable admin privs
      possibly_enable_admin(@user)
      @user.update_attribute(:last_login,Time.now)
      # 'remember me' checked?
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      # finally: reset all store-related session state UNLESS the login
      # was performed as part of a checkout flow
      reset_shopping unless @gCheckoutInProgress
      redirect_to_stored
      flash[:notice] = login_message || "Logged in successfully"
    end
  end

  def destroy
    logout_killing_session!
    clear_facebook_session_information if USE_FACEBOOK
    flash[:notice] = "You have been logged out."
    redirect_to login_path
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:warning] = "Couldn't log you in as '#{params[:email]}'"
    flash[:warning] << ": #{@user.errors.on(:login_failed)}" if @user
    logger.warn "Failed login for '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}: #{flash[:warning]}"
  end

end
