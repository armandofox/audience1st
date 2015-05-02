class ApplicationController < ActionController::Base

  helper :all

  protect_from_forgery
  rescue_from ActionController::InvalidAuthenticityToken, :with => :session_expired

  include AuthenticatedSystem
  include Enumerable
  include ExceptionNotifiable
  include FilenameUtils
  
  filter_parameter_logging :password

  if (RAILS_ENV == 'production' && !SANDBOX)
    include SslRequirement
  else
    def self.ssl_required(*args) ; true ; end
    def self.ssl_allowed(*args) ; true ; end
    def ssl_required? ; nil ; end
    def ssl_allowed? ; nil ; end
  end

  ssl_required

  require 'csv.rb'
  require 'string_extras.rb'
  require 'date_time_extras.rb'
  
  def session_expired
    render :template => 'messages/session_expired', :layout => 'application', :status => 400
    true
  end

  def reset_session # work around session reset bug in rails 2.3.5
    ActiveRecord::Base.connection.execute("DELETE FROM sessions WHERE session_id = '#{request.session_options[:id]}'")
  end

  # set_globals tries to set globals based on current_user, among other things.
  before_filter :set_globals

  def set_globals
    @gAdmin = current_admin
    @disableAdmin = (@gAdmin.is_staff && controller_name=~/customer|store|vouchers/)
    @enableAdmin = session[:can_restore_admin]
    @gCart = find_cart
    @gCheckoutInProgress = !@gCart.cart_empty?
    @gLoggedIn = logged_in_user || Customer.walkup_customer
    true
  end

  def clear_session_state_preserving_auth_token
    session[:cid] = nil   # keeps the session but kill our variable
    session[:admin_id] = nil
    session[:can_restore_admin] = nil
    reset_shopping
  end

  def reset_shopping           # called as a filter
    @cart = find_cart
    @cart.empty_cart!
    session.delete(:promo_code)
    session.delete(:recipient_id)
    session.delete(:cart)
    set_checkout_in_progress(false)
    true
  end

  # a generic filter that can be used by any RESTful controller that checks
  # there's at least one instance of the model in the DB

  def has_at_least_one
    contr = self.controller_name
    klass = Kernel.const_get(contr.singularize.camelize)
    unless klass.find(:first)
      flash[:alert] = "You have not set up any #{contr} yet."
      redirect_to :action => 'new'
    end
  end

  def set_checkout_in_progress(val = true)
    if val
      session[:checkout_in_progress] = val
    else
      session.delete(:checkout_in_progress)
    end
    @gCheckoutInProgress = val
  end

  # Store the action to return to, or URI of the current request if no action given.
  # We can return to this location by calling #redirect_to_stored.
  def return_after_login(where)
    session[:return_to] = (where == :here ? request.request_uri : where)
    true
  end

  def postlogin_action
    session[:return_to] || customer_path(current_user())
  end

  def redirect_to_stored(customer = Customer.find_by_id(session[:cid]))
    if session[:return_to]
      redirect_to session[:return_to]
    elsif customer
      redirect_to customer_path(customer)
    else
      redirect_to login_path
    end
  end

  def find_cart
    Order.find_by_id(session[:cart]) || Order.new
  end

  # setup session etc. for an "external" login, eg by a daemon
  def login_from_external(c)
    session[:cid] = c.id
  end

  # filter that requires user to login before accessing account

  def is_logged_in
    unless logged_in?
      flash[:notice] = "Please log in or create an account in order to view this page."
      redirect_to login_path
      nil
    else
      current_user
    end
  end

  # This will always be called after is_logged_in has setup current_user or has redirected
  def is_myself_or_staff
    desired = Customer.find_by_id(params[:id])
    if (desired.nil? ||
        (desired != current_user && !current_user.is_staff))
      flash[:notice] = "Attempt to perform unauthorized action."
      redirect_to login_path
    end
    @customer = desired
  end

  def temporarily_unavailable
    flash[:alert] = "Sorry, this function is temporarily unavailable."
    redirect_to :back
  end

  # filter that requires login as an admin
  # TBD: these should be defined using a higher-order function but I
  # don't know the syntax for that

  Customer.roles.each do |r|
    define_method "is_#{r}" do
      current_admin.send("is_#{r}")
    end
    define_method "is_#{r}_filter" do
      unless current_admin.send("is_#{r}")
        flash[:notice] = 'You must have at least #{ActiveSupport::Inflector.humanize(r)} privilege for this action.'
        session[:return_to] = request.request_uri
        redirect_to login_path
        return nil
      end
      return true
    end
  end

  def download_to_excel(output,filename="data",timestamp=true)
    (filename << "_" << Time.now.strftime("%Y_%m_%d")) if timestamp
    send_data(output,:type => (request.user_agent =~ /windows/i ?
                               'application/vnd.ms-excel' : 'text/csv'),
              :filename => "#{filename}.csv")
  end

  def email_confirmation(method,*args)
    flash[:notice] ||= ""
    customer = *args.first
    addr = customer.email
    if customer.valid_email_address?
      begin
        Mailer.send("deliver_"<< method.to_s,*args)
        flash[:notice] << " An email confirmation was sent to #{addr}.  If you don't receive it in a few minutes, please make sure 'audience1st.com' is on your trusted senders list, or the confirmation email may end up in your Junk Mail or Spam folder."
        logger.info("Confirmation email sent to #{addr}")
      rescue Exception => e
        flash[:notice] << " Your transaction was successful, but we couldn't "
        flash[:notice] << "send an email confirmation to #{addr}."
        logger.error("Emailing #{addr}: #{e.message} \n #{e.backtrace}")
      end
    else
      flash[:notice] << " Email confirmation was NOT sent because there isn't"
      flash[:notice] << " a valid email address in your Contact Info."
    end
  end

end

