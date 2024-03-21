class SessionsController < ApplicationController

  def new
    redirect_to customer_path(current_user) and return if logged_in?
    @page_title = "Login or Create Account"
    if (@gOrderInProgress)
      @display_guest_checkout = allow_guest_checkout?
    end
    @remember_me = true
    @email ||= params[:email]
    @head = "Subscribers and Returning Customers"
  end

  def new_from_secret
    redirect_after_login(current_user) and return if logged_in?
  end

  def create
    create_session do |params|
      @email = params[:email]
      @remember_me = params[:remember_me]
      u = Customer.authenticate(@email, params[:password])
      if u.nil? || !u.errors.empty?
        note_failed_signin(@email, u)
        redirect_to new_session_path, :email => @email, :remember_me => @remember_me
      else
        u.record_login!
        session.delete(:admin_disabled) # in case admin signin
      end
      u
    end
  end

  def create_from_secret
    create_session do |params|
      permitted = secret_question_params
      @email = params[:email]
      u = Customer.authenticate_from_secret_question(@email, permitted, params[:answer])
      if u.nil? || !u.errors.empty?
        note_failed_signin(@email, u)
        redirect_to (u.errors.has_key?(:no_secret_question) ? login_path : new_from_secret_session_path)
      else
        u.record_login!
      end
      u
    end
  end

  def destroy
    logout_killing_session!
    reset_shopping
    redirect_to login_path, :notice => "You have been logged out."
  end

  def temporarily_disable_admin
    session[:admin_disabled] = true
    redirect_to :back, :notice => "Switched to non-admin user view."
  end

  def reenable_admin
    if session.delete(:admin_disabled)
      flash[:notice] = "Admin view reestablished."
    end
    redirect_to :back
  end

  protected

  def note_failed_signin(attempted_username,customer)
    flash[:alert] = t('login.login_failed')
    flash[:alert] << customer.errors[:login_failed].join(", ") if customer
    Rails.logger.warn "Failed login for '#{attempted_username}' from #{request.remote_ip} at #{Time.current.utc}: #{flash[:alert]}"
  end

  private

  def secret_question_params
    params.permit :secret_question
  end
end
