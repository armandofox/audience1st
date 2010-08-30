class CustomersController < ApplicationController

  require File.dirname(__FILE__) + '/../helpers/application_helper.rb'
  require 'net/http'
  require 'uri'

  helper CustomersHelper

  include Enumerable

  # must be validly logged in before doing anything except login or create acct
  before_filter(:is_logged_in,
                :only=>%w[welcome welcome_subscriber change_password edit link_existing_account],
                :add_to_flash => 'Please log in or create an account to view this page.')
  before_filter :reset_shopping, :only => %w[welcome welcome_subscriber]

  # must be boxoffice to view other customer records or adding/removing vouchers
  before_filter :is_staff_filter, :only => %w[list switch_to search]
  before_filter :is_boxoffice_filter, :only=>%w[merge create]

  # only superadmin can destory customers, because that wreaks havoc
  before_filter(:is_admin_filter,
    :only => ['destroy'],
    :redirect_to => {:action => :list},
    :add_flash => {:notice => 'Only super-admin can delete customer; use Merge instead'})

  # prevent complaints on AJAX autocompletion
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_customer_full_name]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify(:method => :post,
    :only => %w[update finalize_merge destroy create user_create
        send_new_password link_existing_account],
    :redirect_to => { :controller => :customers, :action => :welcome},
    :add_flash => {:warning => "This action requires a POST."} )

  # checks for SSL should be last, as they append a before_filter
  ssl_required :change_password, :new, :create, :user_create, :edit, :forgot_password
  ssl_allowed :auto_complete_for_customer_full_name, :update, :link_user_accounts, :link_existing_account

  # auto-completion for customer search
  def auto_complete_for_customer_full_name
    render :inline => "" and return if params[:__arg].blank?
    @customers =
      Customer.find_by_multiple_terms(params[:__arg].to_s.split( /\s+/ ))
    render(:partial => 'customers/customer_search_result',
           :locals => {:matches => @customers})
  end

  # the default is to show your welcome page, which automatically redirects
  # to login if you're not logged in or to subscriber welcome if you're a
  # subscriber.
  def index ; redirect_to :action => 'welcome' ; end

  # DEPRECATED legacy routes:
  def login ; redirect_to login_path ; end
  def logout ; redirect_to logout_path ; end

  # welcome screen: different for nonsubscribers vs. subscribers

  def welcome                   # for nonsubscribers
    @customer = @gCustomer
    # if customer is a subscriber, AND force_classic is not indicated,
    # redirect to correct page
    if (@customer.subscriber?)
      @subscriber = true
      unless ((params[:force_classic] && @gAdmin.is_boxoffice) ||
              !(Option.value(:force_classic_view).blank?))
        flash.keep :notice
        flash.keep :warning
        redirect_to :action=>'welcome_subscriber'
        return
      end
    else
      @subscriber = nil
    end
    @admin = current_admin
    @page_title = "Welcome, #{@gLoggedIn.full_name.name_capitalize}"
    @vouchers = (@admin.is_boxoffice ?  @customer.vouchers :  @customer.active_vouchers).sort_by(&:created_on).reverse
    session[:store_customer] = @customer.id
  end

  def welcome_subscriber        # for subscribers
    @customer = @gCustomer
    unless @customer.subscriber?
      flash.keep :notice
      flash.keep :warning
      redirect_to :action=>'welcome'
      return
    end
    @admin = current_admin
    @page_title = "Welcome, Subscriber #{@gLoggedIn.full_name.name_capitalize}"
    @vouchers = @customer.active_vouchers.sort_by(&:created_on)
    session[:store_customer] = @customer.id
    @subscriber = true
    # separate vouchers into these categories:
    # unreserved subscriber vouchers, reserved subscriber vouchers, others
    @subscriber_vouchers, @other_vouchers = @vouchers.partition { |v| v.part_of_subscription? }
    @reserved_vouchers,@unreserved_vouchers = @subscriber_vouchers.partition { |v| v.reserved? }
    # find all shows whose run dates overlap the validity period of any voucher.

    # BUG this should be computed from voucher validity period...
    @mindate = Time.now
    @maxdate = (@mindate + 1.year).at_beginning_of_year
    @shows = Show.find(:all, :conditions => ["opening_date > ? OR closing_date < ?",@mindate,@maxdate],
                       :order => "opening_date")
  end

  def link_user_accounts
    #redirect_to login_path unless facebook_session.user
    if self.current_user
      #connect accounts
      fbuid = facebook_session.user.id 
      self.current_user.link_fb_connect(fbuid) unless
        self.current_user.fb_user_id == fbuid
      redirect_to_stored
    else
      #register with fb
      @customer = Customer.create_from_fb_connect(facebook_session.user)
      self.current_user = @customer
      redirect_to :action => 'edit', :id => @customer
    end
  end

  def link_existing_account
    if other = Customer.authenticate(params[:email], params[:password])
      @customer = current_user
      if @customer.merge_automatically!(other)
        flash[:notice] = "Congratulations!  Your accounts are now linked.  You can login either via Facebook or using your email and password."
        redirect_to :action => :welcome, :id => @customer
      else
        flash[:notice] = "Merge failed: #{@customer.errors.full_messages.join(', ')}"
        redirect_to :action => :edit, :id => current_user.id
      end
    end
  end

  def edit
    @customer = current_user
    @is_admin = current_admin.is_staff
    @superadmin = current_admin.is_admin
    # editing contact info may be called from various places. correctly
    # set the return-to so that form buttons can do the right thing.
    @return_to = session[:return_to]
  end

  def update
    @customer = current_user
    @is_admin = current_admin.is_staff
    @superadmin = current_admin.is_admin
    # editing contact info may be called from various places. correctly
    # set the return-to so that form buttons can do the right thing.
    @return_to = session[:return_to]
    # unless admin, remove "extra contact" fields
    params[:customer] = delete_admin_only_attributes(params[:customer]) unless @is_admin
    begin
      # update generic attribs first
      @customer.created_by_admin = @is_admin # to skip validations if admin is editing
      @customer.update_attributes!(params[:customer])
      # if success, and the update is NOT being performed by an admin,
      # clear the created-by-admin flag
      @customer.update_attribute(:created_by_admin, false) if @gLoggedIn == @customer
      flash[:notice] = 'Contact information was successfully updated.'
      if ((newrole = params[:customer][:role])  &&
          newrole != @customer.role_name  &&
          current_admin.can_grant(newrole))
        @customer.update_attribute(:role, Customer.role_value(newrole))
        flash[:notice] << "  Privilege level set to '#{newrole}.'"
      end
      Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => @customer.id,
        :logged_in_id => logged_in_id,
        :comments => flash[:notice])
      if @customer.email_changed? && @customer.valid_email_address? &&
          params[:dont_send_email].blank? 
        # send confirmation email
        email_confirmation(:send_new_password,@customer, nil,
                           "updated your email address in our system")
      end
      redirect_to_stored
    rescue ActiveRecord::RecordInvalid
      flash[:notice] = "Update failed: #{@customer.errors.full_messages.join(', ')}.  Please fix error(s) and try again."
      redirect_to :action => 'edit'
    rescue Exception => e
      flash[:notice] = "Update failed: #{e.message}"
      redirect_to :action => 'edit'
    end
  end

  def change_password
    @customer = current_user
    return if request.get?
    if @customer.update_attributes(params[:customer])
      password = params[:customer][:password]
      flash[:notice] = password.blank? ? "Email confirmed (password unchanged)." : "Email and password are confirmed."
      email_confirmation(:send_new_password,@customer,
        password, "changed your email or password on our system")
      Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :comments => 'Change password')
      redirect_to :action => 'welcome'
    else
      render :action => 'change_password'
    end
  end


  # Following actions are for use by admins only:
  # list, switch_to, merge, search, create, destroy

  def list
    @customers_filter ||= params[:customers_filter]
    conds = Customer.match_any_content_column(@customers_filter)
    @customer_pages, @customers = paginate :customers, :per_page => 100, :order => 'last_name,first_name', :conditions => conds
    @count = Customer.count(:conditions => conds)
    curpage = @customer_pages.current_page
    @title = "#{curpage.first_item} - #{curpage.last_item} of #{@count} matching '#{@customers_filter}'"
  end

  def list_duplicates
    @limit = (params[:limit] || 20).to_i
    @offset = (params[:offset] || 0).to_i
    @customers = Customer.find_suspected_duplicates(@limit,@offset)
    @limit = @customers.length
    @title = "Suspected Duplicates #{@offset+1} - #{@offset+@limit}"
    render :action => 'list'
  end

  def merge
    if (params[:commit] =~ /merge/i) &&
        (!params[:merge] || (params[:merge].keys.length != 2))
      flash[:notice] = 'You must select exactly 2 records at a time to merge.'
      redirect_to_last_list and return
    end
    @cust = params[:merge].keys.map { |x| Customer.find_by_id(x.to_i) }
    if @cust.any? { |c| c.nil? }
      flash[:warning] = "At least one customer not found. Please try again."
      redirect_to_last_list and return
    end
    @offset = params[:offset]
    @last_action_name = params[:action_name]
    # automatic merge?
    case params[:commit]
    when /forget/i, /expunge/i
      flash[:warning] = "Forget and expunge will be implemented soon"
      redirect_to_last_list and return
    when /auto/i
      do_automatic_merge(*params[:merge].keys)
      redirect_to_last_list and return
    when /manual/i
      # fall through to merge.html.haml
    else
      flash[:warning] = "Unrecognized action: #{params[:commit]}"
      redirect_to_last_list and return
    end
  end

  def finalize_merge
    c0 = Customer.find_by_id(params.delete(:cust0))
    c1 = Customer.find_by_id(params.delete(:cust1))
    unless c0 && c1
      flash[:warning] = "At least one customer not found. Please try again."
      redirect_to_last_list and return
    end
    result = c0.merge_with_params!(c1, params)
    # result is nil if merge failed, else string describing result
    flash[:notice] = result || c0.errors.full_messages.join(';')
    redirect_to_last_list
  end

  def switch_to
    if (customer = Customer.find_by_id(params[:id]))
      act_on_behalf_of customer
      reset_shopping
      if params[:target_controller] && params[:target_action]
        redirect_to :controller => params[:target_controller], :action => params[:target_action], :id => customer.id
      else
        redirect_to :controller => 'customers',:action => 'welcome',:id => customer.id
      end
    else
      flash[:notice] = "No such customer: id# #{params[:id]}"
      redirect_to :controller => 'customers', :action => 'list'
    end
  end

  def search
    unless params[:searching]
      render :partial => 'search'
      return
    end
    str = ''
    if params[:match] =~ /any/i
      conds = %w[first_name last_name street city email].map {|x| "#{x} LIKE '%#{params[:any]}%'"}.join(" OR ")
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

  def new
    @is_admin = current_admin.is_boxoffice
    @customer = Customer.new
  end
  
  def create
    @is_admin = true            # needed for choosing correct method in 'new' tmpl
    @customer = Customer.new(params[:customer])
    @customer.created_by_admin = true
    render(:action => 'new') and return unless @customer.save
    (flash[:notice] ||= '') <<  'Account was successfully created.'
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :comments => 'new customer added',
      :logged_in_id => logged_in_id)
    # if valid email, send user a welcome message
    unless params[:dont_send_email]
      email_confirmation(:send_new_password,@customer,
        params[:customer][:password],"set up an account with us")
    end
    current_user = @customer
    @gCheckoutInProgress ? redirect_to_stored : redirect_to(:action => 'switch_to', :id => @customer.id)
  end

  def user_create
    @customer = Customer.new(params[:customer])
    if @gCheckoutInProgress && @customer.day_phone.blank?
      flash[:notice] = "Please provide a contact phone number in case we need to contact you about your order."
      render :action => 'new'
      return
    end
    begin
      @customer.save!
      @customer.update_attribute(:last_login, Time.now)
      flash[:notice] = "Thanks for setting up an account!<br/>"
      email_confirmation(:send_new_password,@customer,
        params[:customer][:password],"set up an account with us")
      self.current_user = @customer
      logger.info "Session cid set to #{session[:cid]}"
      Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => @customer.id,
        :comments => 'new customer self-signup')
      redirect_to_stored
    rescue
      flash[:notice] = "There was a problem creating your account.<br/>"
      render :action => 'new'
    end
  end

  # DANGEROUS METHOD: restricted to super-admin
  # TBD: what this really should do is link all related stuff to
  # the placeholder 'walkup customer'

  def destroy
    p = session[:cid].to_i
    if p == logged_in_id
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
    session[:cid] = @gAdmin.id
    redirect_to :action => 'list'
  end


  #  TBD this method only used by (eg) visits controller to replace-in-place
  # a customer id with a name. Should be obsoleted.
  def lookup
    if ((params[:id].to_i != 0) && (c=Customer.find_by_id(params[:id])))
      render :text => c.full_name
    else
      render(:text => 'No such customer') unless params[:silent]
    end
  end

  # TBD this is an AJAX handler that is called from the partial
  #  _validate.rhtml, which can be rendered as part of the customer
  # _form partial to validate US Mail address.  But first it needs to be
  # connected to a working validation service!

  def validate_address
    cust = params[:customer]
    url = "http://zip4.usps.com/zip4/zcl_0_results.jsp?visited=1&pagenumber=0&firmname=&address2=#{cust[:street]}&address1=&city=#{cust[:city]}&state=#{cust[:state]}&urbanization=&zip5=#{cust[:zip]}"
    res = Net::HTTP.get_response(URI.parse(URI.escape(url)))
    if res.code.to_i == 200 && res.body.match(/.*td headers="full"[^>]+>(.*)<br \/>\s+<\/td>\s+<td style=/m )
      street,csz = Regexp.last_match(1).split /<br \/>/
      city,state,zip = (csz.strip.split( /(&nbsp;)+/ )).values_at(0,2,4)
    end
    render :update do |page|
      page['customer_street'].value = street.strip
      page['customer_city'].value = city.strip
      page['customer_state'].value = state.strip
      page['customer_zip'].value = zip.strip
    end
  end

  def temporarily_disable_admin
    disable_admin
    flash[:notice] = "You are now logged in <strong>without</strong> admin privileges.  Logout and log back in to reestablish admin privileges."
    redirect_to_stored
  end

  def forgot_password
    if request.get?
      set_return_to(params[:redirect_to] || login_path)
    else
      if send_new_password(params[:email])
        redirect_to_stored
      else
        redirect_to :action => 'forgot_password'
      end
    end
  end

  private

  def redirect_to_last_list
    redirect_to :action => (params[:action_name] || 'list'), :customers_filter => params[:customers_filter], :offset => params[:offset]
  end

  def do_automatic_merge(id0,id1)
    c0 = Customer.find_by_id(id0)
    c1 = Customer.find_by_id(id1)
    flash[:notice] ||= ''
    if c0.merge_automatically!(c1)
      flash[:notice] << "Successful merge"
    else
      flash[:notice] = "Automatic merge failed, try merging manually to resolve the following errors:<br/>" + c0.errors.full_messages.join('; ')
    end
  end
  
  def send_new_password(email)
    if email.blank?
      flash[:notice] = "Please enter the email with which you originally signed up, and we will email you a new password."
      return nil
    end
    @customer = Customer.find_by_email(email)
    unless @customer
      flash[:notice] = "Sorry, '#{email}' is not in our database.  You might try under a different email, or create a new account."
      return nil
    end
    begin
      newpass = String.random_string(6)
      @customer.password = @customer.password_confirmation = newpass
      # Save without validations here, because if there is a dup email address,
      # that will cause save-with-validations to fail!
      @customer.save(false)
      email_confirmation(:send_new_password,@customer, newpass,
                         "requested your password for logging in")
      # will reach this point (and change password) only if mail delivery
      # doesn't raise any exceptions
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => @customer.id,
                           :comments => 'Password has been reset')
      return true
    rescue Exception => e
      flash[:notice] = e.message +
        "<br/>Please contact #{Option.value(:help_email)} if you need help."
      return nil
    end
  end

  def delete_admin_only_attributes(params)
    Customer.extra_attributes.each { |a| params.delete(a) }
    params.delete(:comments)
    params
  end

end
