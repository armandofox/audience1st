class ApplicationController < ActionController::Base

  helper :all
  protect_from_forgery

  require 'cart'                # since not an ActiveRecord model
  
  include AuthenticatedSystem
  include Enumerable
  include ExceptionNotifiable
  include ActiveMerchant::Billing
  include FilenameUtils
  
  filter_parameter_logging :credit_card,:password, :number, :type, :verification_value, :year, :month, :swipe_data

  if (RAILS_ENV == 'production' && !SANDBOX)
    include SslRequirement
  else
    def self.ssl_required(*args) ; true ; end
    def self.ssl_allowed(*args) ; true ; end
    def ssl_required? ; nil ; end
    def ssl_allowed? ; nil ; end
  end
  require 'csv.rb'
  require 'string_extras.rb'
  require 'date_time_extras.rb'

  # for Facebook Connect
  if USE_FACEBOOK
    before_filter :set_facebook_session
    helper_method :facebook_session

    rescue_from Facebooker::Session::SessionExpired, :with => :facebook_session_expired

    def facebook_session_expired
      clear_fb_cookies!
      clear_facebook_session_information
      reset_session
      flash[:notice] = "Please login to Facebook again."
      redirect_to login_path
    end
  end

  def reset_session # work around session reset bug in rails 2.3.5
    ActiveRecord::Base.connection.execute("DELETE FROM sessions WHERE session_id = '#{request.session_options[:id]}'")
  end

  # set_globals must happen AFTER Facebook Connect filters, since it will
  # try to set globals based on current_user, among other things.
  before_filter :set_globals

  def set_globals
    @gCustomer = current_user
    @gAdmin = current_admin
    @disableAdmin = (@gAdmin.is_staff && controller_name=~/customer|store|vouchers/)
    @enableAdmin = session[:can_restore_admin]
    @gCart = find_cart
    @gCheckoutInProgress = session[:checkout_in_progress]
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
    @cart.empty!
    session.delete(:promo_code)
    session.delete(:recipient_id)
    session.delete(:store)
    session.delete(:store_customer)
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
      flash[:warning] = "You have not set up any #{contr} yet."
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

  def find_cart
    session[:cart] ||= Cart.new
  end

  def get_filter_info(params,modelname,default=nil,descending=nil)
    cols = eval(ActiveSupport::Inflector.camelize(modelname) + ".columns")
    order = params[:order_by]
    if order.nil? or order.empty?
      if (default)
        order = default
      else
        order = cols.first.name
      end
    end
    order += " DESC" if descending
    conds = nil
    f = params[(ActiveSupport::Inflector.tableize(modelname)+"_filter").to_sym]
    if f && !f.empty?
      fs = "'%" + f.gsub(/\'/, "''") + "%'"
      conds = cols.map { |c| "#{c.name} LIKE #{fs}"}.join(" OR ")
    end
    return conds, order, f
  end

  # setup session etc. for an "external" login, eg by a daemon
  def login_from_external(c)
    session[:cid] = c.id
  end

  # filter that requires user to login before accessing account

  def is_logged_in
    unless logged_in?
      set_return_to
      flash[:notice] = "Please log in or create an account in order to view this page."
      redirect_to login_path
      nil
    else
      current_user
    end
  end

  def not_logged_in
    c = logged_in_id
    unless c.nil? or c.zero?
      flash[:notice] = 'You cannot be logged in to do this action.'
      redirect_to logout_path
      false
    else
      true
    end
  end

  def logged_in_id
    # Return the "effective logged-in ID" for audit purposes (ie to track
    # who did what).
    # if NO ADMIN is logged in, this is the logged-in customer's ID, or the
    #   id of the 'nobody' fake customer if not set.
    # if an admin IS logged in, it's that admin's ID.
    return (session[:admin_id] || session[:cid] || Customer.nobody_id).to_i
  end

  def has_privilege(id,level)
    c = Customer.find_by_id(id)
    return c && (c.role >= level)
  end

  # filter that requires login as an admin
  # TBD: these should be defined using a higher-order function but I
  # don't know the syntax for that

  Customer.roles.each do |r|
    eval <<EOEVAL
    def is_#{r}
      current_admin.is_#{r}
      # (c = Customer.find_by_id(session[:admin_id])) && c.is_#{r}
    end
    def is_#{r}_filter
      unless current_admin.is_#{r}
        flash[:notice] = 'You must have at least #{ActiveSupport::Inflector.humanize(r)} privilege for this action.'
        session[:return_to] = request.request_uri
        redirect_to login_path
        return nil
      end
      return true
    end
EOEVAL
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
        logger.error("Emailing #{addr}: #{e.message}")
      end
    else
      flash[:notice] << " Email confirmation was NOT sent because there isn't"
      flash[:notice] << " a valid email address in your Contact Info."
    end
  end

end

