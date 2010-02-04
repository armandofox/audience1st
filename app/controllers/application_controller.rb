# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all
  #protect_from_forgery

  require 'cart'                # since not an ActiveRecord model
  
  include Enumerable
  include ExceptionNotifiable
  include ActiveMerchant::Billing
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

  before_filter :set_globals
  def set_globals
    @gCustomer = current_customer
    @gAdmin = current_admin
    @gCart = find_cart
    @gCheckoutInProgress = session[:checkout_in_progress]
    @gLoggedIn = (admin=Customer.find_by_id(session[:admin_id])) ? admin : (@gCustomer || Customer.walkup_customer)
    @gNobodyReallyLoggedIn = nobody_really_logged_in
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
    @gCheckoutInProgress = session[:checkout_in_progress] = val
  end

  def reset_shopping           # called as a filter
    @cart = find_cart
    @cart.empty!
    session[:promo_code] = nil
    session[:recipient_id] = nil
    set_checkout_in_progress(false)
    true
  end

  filter_parameter_logging :credit_card,:password

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

  # login a customer
  def login_from_password(c)
    # success
    session[:cid] = c.id
    c.update_attribute(:last_login,Time.now)
    # set redirect-to action based on whether this customer is an admin.
    # authentication succeeded, and customer is NOT in the middle of a
    # store checkout. Proceed to welcome page.
    controller,action = possibly_enable_admin(c)
    reset_shopping unless @gCheckoutInProgress
    c
  end

  # setup session etc. for an "external" login, eg by a daemon
  def login_from_external(c)
    session[:cid] = c.id
  end

  def logout_customer
    reset_session
  end

  # filter that requires user to login before accessing account

  def is_logged_in
    unless (c = Customer.find_by_id(session[:cid])).kind_of?(Customer)
      session[:return_to] = request.request_uri
      redirect_to :controller => 'customers', :action => 'login'
      false
    else
      c
    end
  end

  def not_logged_in
    c = logged_in_id
    unless c.nil? or c.zero?
      flash[:notice] = 'You cannot be logged in to do this action.'
      redirect_to :controller => 'customers', :action => 'logout'
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

  def nobody_really_logged_in
    session[:cid].nil? || session[:cid].to_i.zero?
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
        redirect_to :controller => 'customers', :action => 'login'
        return false
      end
      return true
    end
EOEVAL
  end

  # current_customer is only called from controller actions filtered by
  # is_logged_in, so the find should never fail.
  def current_customer
    Customer.find_by_id(session[:cid].to_i)
  end

  # current_admin is called from controller actions filtered by is_logged_in,
  # so there might in fact be NO admin logged in.
  # So it returns customer record of current admin, if one is logged in;
  # otherwise returns a 'generic' customer with no admin privileges but on
  # which it is safe to call instance methods of Customer.
  def current_admin
    session[:admin_id].to_i.zero? ? Customer.generic_customer : (Customer.find_by_id(session[:admin_id]) || Customer.generic_customer)
  end

  def set_return_to(hsh=nil)
    session[:return_to] = hsh
    true
  end

  def stored_action ; !session[:return_to].nil? ; end

  def redirect_to_stored(params={})
    redirect_to (session[:return_to] || { :controller => 'customers', :action => 'welcome'})
    session[:return_to] = nil
    true
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
        flash[:notice] << " An email confirmation was sent to #{addr}"
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

