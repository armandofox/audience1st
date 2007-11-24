class CustomersController < ApplicationController

  require File.dirname(__FILE__) + '/../helpers/application_helper.rb'
  require 'net/http'
  require 'uri'
  
  # must be validly logged in before doing anything except login itself
  before_filter(:is_logged_in,
                :only=>%w[welcome welcome_subscriber change_password edit update],
                :redirect_to => {:action=>:login},
                :add_to_flash => 'Please log in or create an account to view this page.')
  before_filter :not_logged_in, :only => %w[user_create]
  
  # must be boxoffice to view other customer records or adding/removing vouchers
  before_filter :is_staff_filter, :only => %w[list show search]
  before_filter :is_boxoffice_filter, :only=>%w[merge create]

  # only superadmin can destory customers, because that wreaks havoc
  before_filter(:is_admin_filter,
                :only => ['destroy'],
                :redirect_to => {:action => :list},
                :add_to_flash => 'Only super-admin can delete customer; use Merge instead')

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify(:method => :post,
         :only => %w[destroy create update user_create],
         :redirect_to => { :action => :welcome })

  # the default is to show your welcome page, which automatically redirects
  # to login if you're not logged in or to subscriber welcome if you're a
  # subscriber.
  def index ; redirect_to :action => 'welcome' ; end
  
  # login and logout
  def login
    if (@checkout_in_progress = session[:checkout_in_progress])
      @cart = find_cart
    end
    return unless request.post? # just show login page
    return unless params[:customer]
    l = params[:customer][:login].to_s.strip
    p = params[:customer][:password].to_s.strip
    # if customer clicked 'forgot password' box, send email
    return forgot_password(l) if  params[:forgot_password]
    # did customer leave login field or password blank?
    if (l.blank?) || (p.blank?)
      flash[:notice] = "Please provide both your email address and password."
      logger.info("Empty login or password: login=<#{l}>")
      return
    end
    # try authenticate
    if (c = Customer.authenticate(l,p)).kind_of?(Customer)
      # success
      session[:cid] = c.id
      c.update_attribute(:last_login,Time.now)
      # is this an admin-enabled login?
      if c.is_staff # the least privilege level that allows seeing other customer accts
        (flash[:notice] ||= '') << 'Logged in as Administrator ' + c.first_name
        session[:admin_id] = c.id
        action = 'list'
      else
        session[:admin_id] = nil
        action = 'welcome'
      end
      if @checkout_in_progress
        redirect_to(:controller => 'store', :action => 'checkout', :id => c.id)
        return
      end
      # authentication succeeded, and customer is NOT in the middle of a
      # store checkout. Proceed to welcome page.
      session[:promo_code] = nil
      session[:store_customer] = nil
      redirect_to :action => action
      return
    else
      # authentication failed
      case c
      when :login_not_found
        flash[:notice] = "Can't find that email address in our database. " <<
          "Maybe you signed up with a different address?  If not, click " <<
          "Create Account to create a new account."
        logger.info("Login not found: #{l}")
      when :bad_password
        flash[:notice] = "We recognize your email address, but you mistyped " <<
          "your password. If you've forgotten your password, just enter " <<
          "your email address, check the Forgot My Password box, and " <<
          "click Continue, and we will email you a new password."
        logger.info("Bad password supplied for login #{l}")
      else
        flash[:notice] = "Login unsuccessful"
        logger.error("Bad login, don't know why, for login #{l}")
      end
      # by default, this will fall thru to re-rendering the login view.
    end
  end

  def logout
    reset_session
    @customer = nil
    (flash[:notice] ||= '') << 'You have successfully logged out.' <<
      " Thanks for supporting #{APP_CONFIG[:venue]}!"
    redirect_to :action => 'login'       # no separate logout screen.
  end

  # welcome screen: different for nonsubscribers vs. subscribers
  
  def welcome
    # welcome screen for nonsubscribers
    @customer = current_customer
    # if customer is a subscriber, redirect to correct page
    redirect_to(:action=>'welcome_subscriber') and return if @customer.is_subscriber?
    # can also be reached by an admin 'acting on behalf of' a customer.
    @admin = current_admin
    @page_title = "Welcome, #{@customer.full_name}"
    @vouchers = @customer.active_vouchers.sort { |x,y| x.created_on <=> y.created_on }
    session[:store_customer] = @customer.id
  end

  def welcome_subscriber
    # welcome screen for subscribers
    @customer = current_customer
    # can also be reached by an admin 'acting on behalf of' a customer.
    @admin = current_admin
    # make sure customer is really a subscriber; else, show nonsubscriber page
    redirect_to(:action=>'welcome') and return unless @customer.is_subscriber?
    @page_title = "Welcome, Subscriber #{@customer.full_name}"
    @vouchers = @customer.active_vouchers.sort { |x,y| x.created_on <=> y.created_on }
    session[:store_customer] = @customer.id
  end

  def update
    @customer,@is_admin = for_customer(params[:id])
    flash[:notice] = ''
    # squeeze empty-string params into nils.
    params[:customer].each_pair { |k,v| params[:customer][k] = nil if v.blank? }
    # unless admin, remove "extra contact" fields
    unless @is_admin
      Customer.extra_attributes.each { |a| params[:customer].delete(a) }
      flash[:notice] << "Warning: Some new attribute values were ignored<br/>"
    end
    old_login  = @customer.login
    # make sure user is empowered to do this.
    unless (params[:id].to_i == session[:cid].to_i) || is_boxoffice
      flash[:notice] << "You can update only your own contact information."
      redirect_to :action => 'welcome', :id => @customer
      return
    end
    #
    #  special case: updating 'role' (privilege) is protected attrib
    #
    if ((newrole = params[:customer][:role]) &&
        (Customer.role_value(newrole) != Customer.role_value(@customer.role)))
      if Customer.find(logged_in_id).can_grant(newrole)
        @customer.role = Customer.role_value(params[:customer][:role])
        @customer.save!
        confirm = "Role set to #{newrole}<br/>"
        Txn.add_audit_record(:txn_type => 'edit',
                             :customer_id => params[:id],
                             :logged_in_id => logged_in_id,
                             :comments => confirm)
        flash[:notice] << confirm
      else
        flash[:notice] << "Change of patron privilege level is disallowed. "
      end
    end
    params[:customer].delete(:comments) unless @is_admin
    # update generic attribs
    # if login is empty - make it nil to avoid failing validation
    params[:customer].delete(:login) if params[:customer][:login].to_s.empty?
    if @customer.update_attributes(params[:customer])
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => params[:id],
                           :logged_in_id => logged_in_id)
      flash[:notice] << 'Contact information was successfully updated.'
      if (@customer.login != old_login) && @customer.has_valid_email_address?
        # send confirmation email
        email_confirmation(:send_new_password,@customer, nil,
                           "updated your email address in our system")
      end
    else                      # update was legal to try, but it failed
      flash[:notice] << 'Information was NOT updated: ' + @customer.errors.full_messages.join("; ")
    end
    redirect_to :action => 'edit', :id => @customer
  end
    
  def change_password
    @customer,@is_admin = for_customer(params[:id])
    if (request.post?)
      pass = params[:customer][:password].to_s rescue nil
      if (pass.nil? || pass.empty?)
        flash[:notice] = "You must set a password."
        render :action => 'change_password', :id => @customer
        return
      else
        pass.strip!
        @customer.password = pass
        if (@customer.save)
          flash[:notice] = "Password has been changed."
          email_confirmation(:send_new_password,@customer,
                             pass, "changed your password on our system")
          Txn.add_audit_record(:txn_type => 'edit',
                               :customer_id => @customer.id,
                               :comments => 'Change password')
          redirect_to :action => 'welcome', :id => @customer.id
        end
      end
    end
  end
 
  def edit
    # an admin can edit any customer from the listing screen, but a non-admin
    # can only edit their own info and only if already logged in
    @customer,@is_admin = for_customer(params[:id])
    # this is the one place the customer's Role (privilege) can be changed
    @superadmin = is_admin
  end


  def user_create
    @customer = Customer.new(params[:customer])
    if (@checkout_in_progress = session[:checkout_in_progress])
      @cart = find_cart
    end
    @customer.validation_level = 0
    flash[:notice] = ''
    unless @customer.has_valid_email_address?
      flash[:notice] = "Please provide a valid email address as your login ID."
      render :action => 'new'
      return
    end
    if @customer.save
      @customer.update_attribute(:last_login, Time.now)
      flash[:notice] = "Thanks for setting up an account!<br/>"
      email_confirmation(:send_new_password,@customer,
                         params[:customer][:password],"set up an account with us")
      session[:cid] = @customer.id
      logger.info "Session cid set to #{session[:cid]}"
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => @customer.id,
                           :comments => 'new customer self-signup')
      if session[:checkout_in_progress]
        redirect_to :controller => 'store', :action => 'checkout', :id => @customer.id
      else
        redirect_to :action => 'welcome', :id => @customer.id
      end
    else
      flash[:notice] = "There was a problem creating your account.<br/>"
      render :action => 'new'
    end
  end
  
  def new
    @is_admin = is_boxoffice
    @customer = Customer.new
    if (@checkout_in_progress = session[:checkout_in_progress])
      @cart = find_cart
    end
  end

  # Following actions are for use by admins only:
  # list, merge, search, create, destroy

  def list
    @is_admin = is_admin
    @conds,@o, @customers_filter = get_filter_info(params, :customer, :last_name)
    if (@conds)
      @count = Customer.count(:conditions => @conds)
      @customer_pages, @customers = paginate :customers, :per_page => 20, :order => @o, :conditions => @conds
    else
      # list all
      @count = Customer.count
      @customer_pages, @customers = paginate :customers,  :order_by => @o, :per_page => 20
    end
  end

  def merge
    if request.get?
      # display info from two records and allow selection
      if (!params[:merge]) || (params[:merge].keys.length != 2)
        flash[:notice] = 'You must select exactly 2 records at a time to merge'
        redirect_to :action => 'list'
      else
        @cust = params[:merge].keys.map { |x| Customer.find(x.to_i) }
        # fall through to merge.rhtml
      end
    else                        # post: do the merge
      begin
        # do the merge
        c0 = Customer.find(params.delete(:cust0))
        c1 = Customer.find(params.delete(:cust1))
        result,msg = c0.merge_with(c1, params)
        # result (boolean) is whether it worked, msg is error/success msg
        flash[:notice] = msg
      rescue Exception => e
        flash[:notice] = "Problems during merge: #{e.message}"
      end
      redirect_to :action => 'welcome', :id => c0.id
    end
  end

  def search
    unless params[:searching]
      render :partial => 'search'
      return
    end
    str = ''
    if params[:match] =~ /any/i
      conds = %w[first_name last_name street city login].map {|x| "#{x} LIKE '%#{params[:any]}%'"}.join(" OR ")
    else
      k = params[:customer].keys
      if k.empty?
        flash[:notice] = "Please enter some constraints"
        render :partial => 'search'
      else
        conds = [ k.map { |x| "#{x} LIKE ?"}.join(" AND ") ] +
          params[:customer].values_at(*k).map { |s| "%#{s}%" }
      end
    end
    @customers = Customer.find(:all, :conditions => conds)
    render :partial => 'search_results'
  end

  def create
    @is_admin = true            # needed for choosing correct method in 'new' tmpl
    @checkout_in_progress = session[:checkout_in_progress]
    flash[:notice] = ''
    # if neither email address nor password was given, assign a random
    # password so validation doesn't fail.
    if params[:customer][:password].to_s.empty? &&
        params[:customer][:login].to_s.empty?
        # assign a random password
      params[:customer][:login] = nil
      params[:customer][:password] =
        params[:customer][:password_confirmation] = String.random_string(6)
    end
    @customer = Customer.new(params[:customer])
    # then must have a password too....
    @customer.validation_level = 1 # 1 means hand-validated by staff
    if @customer.save
      flash[:notice] <<  'Account was successfully created.'
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => @customer.id,
                           :comments => 'new customer added',
                           :logged_in_id => logged_in_id)
      # if valid email, send user a welcome message
      email_confirmation(:send_new_password,@customer,
                         params[:customer][:password],"set up an account with us")
      redirect_to :action => 'welcome', :id => @customer.id
    else
      flash[:notice] << 'Errors creating account'
      render :action => 'new'
    end
  end

  def destroy
    p = params[:id].to_i
    if p == logged_in_id.to_i
      flash[:notice] = "Can't delete yourself while logged in"
    elsif p.zero?
      flash[:notice] = "Can't delete placeholder customer 0"
    else
      begin
        c = Customer.find(p)
        msg = "Customer '#{c.full_name}' (ID #{c.id}) permanently deleted"
        c.destroy
        flash[:notice] = msg
      rescue Exception => e
        flash[:notice] = "Error deleting customer: #{e.message}"
      end
    end
    redirect_to :action => 'list'
  end


  def lookup
    if ((params[:id].to_i != 0) && (c=Customer.find_by_id(params[:id])))
      render :text => c.full_name
    else
      render(:text => 'No such customer') unless params[:silent]
    end
  end

  # this is an AJAX handler
  def validate_address
    cust = Customer.find(params[:id])
    formdata = "#{cust[:street]}\n#{cust[:city]}, #{cust[:state]} #{cust[:zip]}"
    url = APP_CONFIG[:address_validation_url]
    res = Net::HTTP.post_form(URI.parse(url), {'address' => formdata})
    if !(res.body.match(/address was rejected/i)) &&
        res.body.match(/<PRE><FONT SIZE=\+2>([^<]+)<\/FONT><\/PRE>/i)
      newaddr = $1
      if newaddr.match( /(.+)$\s*\b(.+)\b\s+(\w\w)\s+([-\d]+)/ )
        cust.street = Regexp.last_match(1)
        cust.city = Regexp.last_match(2)
        cust.state = Regexp.last_match(3)
        cust.zip = Regexp.last_match(4)
        cust.validation_level = 2
      end
    end
    render :partial => 'form', :locals => {:customer => cust }
  end


  private

  def forgot_password(login)
    if login.blank?
      flash[:notice]="Please enter the email address with which you originally"
      flash[:notice]<<"signed up, and we will email you a new password."
      # do we already know this person?
    elsif ! login.valid_email_address?
      flash[:notice] = "'#{login}' does not appear to be a valid email address."
    elsif ! (@customer = Customer.find_by_login(login))
      flash[:notice] = "Sorry, '#{login}' is not in our database.  You might try under a different email address, or create a new account."
    else    # reset the password and email it to them
      begin
        newpass = String.random_string(6)
        @customer.password = newpass
        @customer.save!
        email_confirmation(:send_new_password,@customer, newpass,
                           "requested your password for logging in")
        # will reach this point (and change password) only if mail delivery
        # doesn't raise any exceptions
        Txn.add_audit_record(:txn_type => 'edit',
                             :customer_id => @customer.id,
                             :comments => 'Password has been reset')
      rescue Exception => e
         flash[:notice] = e.message +
           "<br/>Please contact #{APP_CONFIG[:help_email]} if you need help."
      end
    end
    redirect_to :action => :login
  end
  
end
