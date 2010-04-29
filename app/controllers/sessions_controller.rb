# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  ssl_required :new, :create

  # render new.rhtml
  def new
    @page_title = "Login or Create Account"
    if (@gCheckoutInProgress)
      @cart = find_cart
    end
  end

  def create
    logout_keeping_session!
    @user = Customer.authenticate(params[:login], params[:password])
    if (@user.nil? || !@user.errors.empty?)
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    else
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = @user
      @user.update_attribute(:last_login,Time.now)
      # 'remember me' checked?
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      # if user is an admin, enable admin privs
      possibly_enable_admin(@user)
      # finally: reset all store-related session state UNLESS the login
      # was performed as part of a checkout flow
      reset_shopping unless @gCheckoutInProgress
      #redirect_to_stored if (@gCheckoutInProgress || stored_action)
      redirect_to_stored
      flash[:notice] = "Logged in successfully"
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_to_stored
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:warning] = "Couldn't log you in as '#{params[:login]}'"
    flash[:warning] << ": #{@user.errors.on(:login_failed)}" if @user
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}: #{flash[:error]}"
  end

  def possibly_enable_admin(c = Customer.generic_customer)
    session[:admin_id] = nil
    if c.is_staff # least privilege level that allows seeing other customer accts
      (flash[:notice] ||= '') << 'Logged in as Administrator ' + c.first_name
      session[:admin_id] = c.id
      return ['customers', 'list']
    elsif c.subscriber?
      return ['customers', 'welcome_subscriber']
    else
      return ['store', 'index']
    end
  end

end
