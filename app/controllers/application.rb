# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Enumerable
  include ExceptionNotifiable
  include ActiveMerchant::Billing
  include SslRequirement
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
    true
  end
  
  filter_parameter_logging :credit_card,:password

  def find_cart
    session[:cart] ||= Cart.new
  end

  def get_filter_info(params,modelname,default=nil,descending=nil)
    cols = eval(Inflector.camelize(modelname) + ".columns")
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
    f = params[(Inflector.tableize(modelname)+"_filter").to_sym]
    if f && !f.empty?
      fs = "'%" + f.gsub(/\'/, "''") + "%'"
      conds = cols.map { |c| "#{c.name} LIKE #{fs}"}.join(" OR ")
    end
    return conds, order, f
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
        flash[:notice] = 'You must have at least #{Inflector.humanize(r)} privilege for this action.'
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
    Customer.find_by_id(session[:cid].to_i, :include => :vouchers)
  end

  # current_admin is called from controller actions filtered by is_logged_in,
  # so there might in fact be NO admin logged in.
  # So it returns customer record of current admin, if one is logged in;
  # otherwise returns a 'generic' customer with no admin privileges but on
  # which it is safe to call instance methods of Customer.
  def current_admin
    Customer.find_by_id(session[:admin_id]) || Customer.generic_customer
  end

  def redirect_to_stored(params={})
    return_to = session[:return_to].to_s
    unless (return_to.blank? ||  return_to == url_for(:controller => 'customers', :action => 'login'))
      session[:return_to] = nil
      redirect_to_url(return_to,params)
    else
      redirect_to({:controller => 'customers', :action => 'welcome'}.merge(params))
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
    if customer.has_valid_email_address?
      begin
        Mailer.send("deliver_"<< method.to_s,*args)
        flash[:notice] << " An email confirmation was sent to #{customer.login}"
        logger.info("Confirmation email sent to #{customer.login}")
      rescue Exception => e
        flash[:notice] << " Your transaction was successful, but we couldn't "
        flash[:notice] << "send an email confirmation to #{customer.login}."
        logger.error("Emailing #{customer.login}: #{e.message}")
      end
    else
      flash[:notice] << " Email confirmation was NOT sent because there isn't"
      flash[:notice] << " a valid email address in your Contact Info."
    end
  end

end

# the following allows functional tests to not choke on the user_agent method,
# since by default TestRequest doesn't provide that method.

module ActionController
  class TestRequest < AbstractRequest
    attr_accessor :user_agent
  end
end
