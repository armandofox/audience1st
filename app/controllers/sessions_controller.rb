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

  def new_from_secret_question
    redirect_to_stored and return if logged_in?
  end

  def create_from_secret_question
    create_session do |params|
    # If customer logged in using this mechanism, force them to change password.
      u = Customer.authenticate_from_secret_question(params[:email], params[:secret_question], params[:answer])
      if u.nil? || !u.errors.empty?
        note_failed_signin(u)
        if u.errors.on(:login_failed) =~ /never set up a secret question/i
          redirect_to login_path
        else
          redirect_to secret_question_path
        end
      end
      set_return_to change_password_path(u)
      u
    end
  end

  def not_me
    logout_keeping_session!
    set_return_to :controller => 'store', :action => 'checkout'
    set_checkout_in_progress(true)
    flash[:notice] = "Please sign in, or if you don't have an account, please enter your billing information."
    @cust = Customer.new
    redirect_to login_path
  end
  
  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_to login_path
  end

  protected
  
  def create_session
    logout_keeping_session!
    @user = yield(params)
    if @user && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = @user
      # if user is an admin, enable admin privs
      @user.update_attribute(:last_login,Time.now)
      # 'remember me' checked?
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      # finally: reset all store-related session state UNLESS the login
      # was performed as part of a checkout flow
      reset_shopping unless @gCheckoutInProgress
      redirect_to_stored(@user)
    end
  end

  # Track failed login attempts
  def note_failed_signin(user)
    flash[:alert] = "Couldn't log you in as '#{params[:email]}'"
    flash[:alert] << ": #{user.errors.on(:login_failed)}" if user
    logger.warn "Failed login for '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}: #{flash[:alert]}"
  end

end
