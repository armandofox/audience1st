class CustomersController < ApplicationController

  require File.dirname(__FILE__) + '/../helpers/application_helper.rb'
  require 'net/http'
  require 'uri'

  helper CustomersHelper

  include Enumerable

  # must be validly logged in before doing anything except login or create acct
  before_filter(:is_logged_in,
                :only=>%w[welcome change_password change_secret_question edit link_existing_account],
                :add_to_flash => 'Please log in or create an account to view this page.')
  before_filter :reset_shopping, :only => %w[welcome]

  # must be boxoffice to view other customer records or adding/removing vouchers
  before_filter :is_staff_filter, :only => %w[list list_duplicates switch_to search]
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
  ssl_required :change_password, :change_secret_question, :new, :create, :user_create, :edit, :forgot_password
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

  def welcome
    @customer = @gCustomer
    @admin = current_admin
    @vouchers = @customer.active_vouchers.sort_by(&:created_on)
    session[:store_customer] = @customer.id

    name = @gLoggedIn.full_name.name_capitalize
    @subscriber = @customer.subscriber?
    if @subscriber
      @package_type =  'Season Subscription'
      @page_title = "Welcome, Subscriber #{name}"
    else
      @package_type = 'Ticket Package'
      @page_title = "Welcome, #{name}"
    end
    # separate vouchers into these categories:
    # unreserved subscriber vouchers, reserved subscriber vouchers, others
    @subscriber_vouchers, @other_vouchers =
      @vouchers.partition { |v| v.subscriber_voucher? }
    @vouchers_by_season = @subscriber_vouchers.group_by(&:season)
    @reserved_vouchers,@unreserved_vouchers =
      @subscriber_vouchers.partition { |v| v.reserved? }
    flash[:notice] = (@current_user.login_message || "Logged in successfully") if new_session?
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
      flash[:warning] = "To use this feature, you must have an existing Facebook account."
      redirect_to login_path
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
      @customer.update_labels!(params[:label] ? params[:label].keys.map(&:to_i) : nil)
      # if success, and the update is NOT being performed by an admin,
      # clear the created-by-admin flag
      @customer.update_attribute(:created_by_admin, false) if @gLoggedIn == @customer
      flash[:notice] = "Contact information for #{@customer.full_name} successfully updated."
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
      flash[:notice] = "Changes confirmed."
      email_confirmation(:send_new_password,@customer,
        password, "changed your password on our system")
      Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :comments => 'Change password')
      redirect_to :action => 'welcome'
    else
      render :action => 'change_password'
    end
  end

  def change_secret_question
    @customer = current_user
    return if request.get?
    if @customer.update_attributes(params[:customer])
      Txn.add_audit_record(:txn_type => 'edit', :customer_id => @customer.id,
        :comments => 'Change secret question or answer')
      flash[:notice] = 'Secret question change confirmed.'
      redirect_to home_path
    else
      render :action => :change_secret_question
    end
  end

  # Following actions are for use by admins only:
  # list, switch_to, merge, search, create, destroy

  def list
    @offset,@limit = get_list_params 
    @customers_filter ||= params[:customers_filter]
    conds = Customer.match_any_content_column(@customers_filter)
    @customers = Customer.find(:all,
      :conditions => conds,
      :offset => @offset,
      :limit => @limit,
      :order => 'last_name,first_name'
      )
    @count = @customers.length
    count_all = Customer.count(:conditions => conds)
    @previous = (@offset <= 0 ? nil : [@offset - @limit, 0].max)
    @next = (@offset + @count < count_all ? @offset + @count : nil)
    @title = (@count.zero? ? "No matches" : @count == 1 ? "1 record" :
      "Matches #{@offset+1} - #{@offset+@count} of #{count_all}")
    @title += " for '#{@customers_filter}'" unless @customers_filter.empty?
  end

  def list_duplicates
    @offset,@limit = get_list_params
    @customers = Customer.find_suspected_duplicates(@limit,@offset)
    @count = @customers.length
    @previous = [@offset - @limit, 0].max
    @next = @offset + [@limit,@count].min
    @title = "Suspected Duplicates #{@offset+1} - #{@offset+@count}"
    render :action => 'list'
  end

  def merge
    if !params[:merge] || params[:merge].keys.length < 1
      flash[:notice] = 'You have not selected any customers.'
      redirect_to_last_list and return
    end
    ids = params[:merge].keys
    if (params[:commit] =~ /merge/i) && (ids.length != 2)
      flash[:notice] = 'You must select exactly 2 records at a time to merge.'
      redirect_to_last_list and return
    end
    @cust = ids.map { |x| Customer.find_by_id(x.to_i) }
    if @cust.any? { |c| c.nil? }
      flash[:warning] = "At least one customer not found. Please try again."
      redirect_to_last_list and return
    end
    @offset = params[:offset]
    @last_action_name = params[:action_name]
    # automatic merge?
    case params[:commit]
    when /forget/i
      count = do_deletions(@cust, :forget!)
      flash[:warning] = "#{count} customers forgotten (their transactions have been preserved)<br/> #{flash[:warning]}"
      redirect_to_last_list and return
    when /expunge/i
      count = do_deletions(@cust, :expunge!)
      flash[:warning] = "#{count} customers (and their transactions) expunged<br/> #{flash[:warning]}"
      redirect_to_last_list and return
    when /auto/i
      do_automatic_merge(*params[:merge].keys)
      redirect_to_last_list and return
    when /manual/i
      render :action => :merge
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
    logger.info "Merging <#{c1}> into <#{c0}>: #{flash[:notice]}"
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
    flash[:notice] = "Switched to non-admin user view."
    redirect_to_stored
  end

  def reenable_admin
    session[:admin_id] = nil    # fail-safe, will remain this way if reenable fails
    if session[:can_restore_admin] &&
        (c = Customer.find_by_id(session[:can_restore_admin])) &&
        possibly_enable_admin(c)
      flash[:notice] = "Admin view reestablished."
    else
      flash[:notice] = "Could not reinstate admin privileges.  Try logging out and back in."
    end
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

  def get_list_params
    offset = [params[:offset].to_i, 0].max
    limit = [params[:limit].to_i, 20].max
    return [offset,limit]
  end

  def do_deletions(customers, method)
    count = 0
    flash[:warning] = ''
    customers.each do |c|
      c.send(method)
      if c.errors.empty?
        count += 1
      else
        flash[:warning] << c.errors.full_messages.join("<br/>")
      end
    end
    count
  end

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
