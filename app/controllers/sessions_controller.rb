# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.rhtml
  def new
    redirect_to customer_path(current_user) and return if logged_in?
    @page_title = "Login or Create Account"
    if (@gCheckoutInProgress)
      @cart = find_cart
    end
    @remember_me = true
    @email ||= params[:email]
  end

  def new_from_secret
    redirect_after_login(current_user) and return if logged_in?
  end

  def create
    create_session do |params|
      u = Customer.authenticate(params[:email], params[:password])
      if u.nil? || !u.errors.empty?
        note_failed_signin(u)
        @email = params[:email]
        @remember_me = params[:remember_me]
        render :action => :new
      end
      u
    end
  end

  def create_from_secret
    create_session do |params|
    # If customer logged in using this mechanism, force them to change password.
      u = Customer.authenticate_from_secret_question(params[:email], params[:secret_question], params[:answer])
      if u.nil? || !u.errors.empty?
        note_failed_signin(u)
        if u.errors.on(:login_failed) =~ /never set up a secret question/i
          redirect_to login_path
        else
          redirect_to new_from_secret_session_path
        end
        return
      end
      u
    end
  end

  def destroy
    logout_killing_session!
    redirect_with login_path, :notice => "You have been logged out."
  end

  def temporarily_disable_admin
    session[:admin_disabled] = true
    redirect_with :back, :notice => "Switched to non-admin user view."
  end

  def reenable_admin
    if session.delete(:admin_disabled)
      flash[:notice] = "Admin view reestablished."
    end
    redirect_to :back
  end
  

  protected
  

  # Track failed login attempts
  def note_failed_signin(user)
    flash[:alert] = "Couldn't log you in as '#{params[:email]}'"
    flash[:alert] << ": #{user.errors.on(:login_failed)}" if user
    logger.warn "Failed login for '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}: #{flash[:alert]}"
  end

end
