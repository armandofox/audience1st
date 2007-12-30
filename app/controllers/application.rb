# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class String

  def self.random_string(len)
    # generate a random string of alphanumerics, but to avoid user confusion,
    # omit o/0 and 1/i/l
    newpass = ''
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a - %w[O o L l I i]
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def valid_email_address?
    return self && self.match( /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.([A-Z]{2,4})?$/i )
  end

  def default_to(val)
    self.to_s.empty? ? val : self.to_s
  end
  @@name_connectors = %w[and & van von der de di]
  @@name_prefixes = /^m(a?c)(\w+)/i
  def capitalize_name_word
    # short all-caps (like "OJ") are left as-is
    return self if self.match(/^[A-Z]+$/)
    # words that are already BiCapitalized are left as-is
    # (i.e., contain at least one uppercase letter that is preceded by
    # a lowercase letter; catches McHugh, diBlasio, etc.)
    return self if self.match( /[a-z][A-Z]/ )
    # single initial: capitalize the initial
    return "#{self.upcase}." if self.match(/^\w$/i)
    # connector word (von, van, de, etc.) - lowercase
    return self.downcase if @@name_connectors.include?(self.downcase)
    # default: capitalize first letter
    return self.sub(/^(\w)/) { |a| a.upcase }
    #self.match(@@name_prefixes) ? self.sub(@@name_prefixes, "M#{$1}#{$2.capitalize}") :
    # self.capitalize
  end
  def name_capitalize
    self.split(/[\., ]+/).map { |w| w.capitalize_name_word }.join(" ")
  end
end

class Time
  def speak(args={})
    res = []
    unless args[:omit_date]
      res << strftime("%A, %B %e")
    end
    unless args[:omit_time]
      say_min = min.zero? ? "" :  min < 10 ? "oh #{min}" : min
      res<<"#{self.strftime('%I').to_i} #{say_min} #{self.strftime('%p')[0,1]} M"
    end
    res.join(", at ")
  end
  def self.new_from_hash(h)
    return Time.now unless h.respond_to?(:has_key)
    if h.has_key?(:hour)
      Time.local(h[:year].to_i,h[:month].to_i,h[:day].to_i,h[:hour].to_i,
               (h[:minute] || "00").to_i,
               (h[:second] || "00").to_i)
    else
      Time.local(h[:year].to_i,h[:month].to_i,h[:day].to_i)
    end
  end
  def date_part
    Date.parse(self.strftime("%D"))
  end
end

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include ActiveMerchant::Billing
  include SslRequirement
  require 'csv.rb'

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


  # given results of a form submission containing a select for dollar
  # amount, return the amount
  def amount_from_selects(hsh)
    base = 1
    amt = 0
    hsh.keys.sort.reverse.each do |k|
      amt += hsh[k].to_i * base
      base *= 10
    end
    amt
  end

  # filter that requires user to login before accessing account
  
  def is_logged_in
    unless (c = Customer.find_by_id(session[:cid])).kind_of?(Customer)
      flash[:notice] = 'You must sign in to view this page.'
      session[:return_to] = request.request_uri
      redirect_to :controller => 'customers', :action => 'login'
      logger.info("Is_logged_in returns false for id=#{c} for request:\n#{request}")
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
      (c = Customer.find_by_id(session[:admin_id])) && c.is_#{r}
    end
    def is_#{r}_filter
      unless is_#{r}
        flash[:notice] = 'You must have at least #{Inflector.humanize(r)} privilege for this action.'
        session[:return_to] = request.request_uri
        redirect_to :controller => 'customers', :action => 'login'
        false
      end
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

  def get_payment_gateway_info(card_present=nil)
    gwtype = APP_CONFIG[:gateway_type]
    gwacct = Inflector.underscore(gwtype) +
      (RAILS_ENV == 'production' ?
       (card_present ? '_cp_account' : '_account') :
       '_test_account')
    gw =  APP_CONFIG[gwacct.to_sym]
    # some gateways require a PEM, others don't.  if filename is nonempty,
    # it names the file containing PEM; otherwise PEM not needed.
    if gw['pemfile'] and !gw['pemfile'].empty?
      gw['pem'] = File.read("#{RAILS_ROOT}/config/#{gw['pemfile']}")
    end
    #gw['gateway'] = Module.const_get(gwtype + 'Gateway')
    gw['gateway'] = AuthorizedNetGateway
    gw.symbolize_keys
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
