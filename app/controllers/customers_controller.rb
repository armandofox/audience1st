class CustomersController < ApplicationController


  # Actions requiring no login, customer login, and staff login respectively
  ACTIONS_WITHOUT_LOGIN = %w(new user_create forgot_password home)
  CUSTOMER_ACTIONS =      %w(show edit update change_password_for change_secret_question)
  ADMIN_ACTIONS =         %w(auto_complete_for_customer_full_name lookup create
                            search merge finalize_merge index list_duplicate)

  # All these filters redirect to login if trying to trigger an action without correct preconditions.
  before_filter :is_logged_in, :except => ACTIONS_WITHOUT_LOGIN
  before_filter :is_myself_or_staff, :only => CUSTOMER_ACTIONS
  before_filter :is_staff_filter, :only => ADMIN_ACTIONS

  def home
    if current_user
      redirect_to customer_path(current_user)
    else
      redirect_to login_path
    end
  end

  # actions requiring @customer to be set by is_myself_or_staff

  def show
    reset_shopping
    @admin = current_user.is_staff
    @vouchers = @customer.active_vouchers.sort_by(&:created_at)
    session[:store_customer] = @customer.id

    name = @customer.full_name.name_capitalize
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

  def edit
    @is_admin = current_user.is_staff
    @superadmin = current_user.is_admin
    # editing contact info may be called from various places. correctly
    # set the return-to so that form buttons can do the right thing.
    @return_to = session[:return_to]
  end

  def update
    @is_admin = current_user.is_staff
    @superadmin = current_user.is_admin
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
      @customer.update_attribute(:created_by_admin, false) if current_user == @customer
      flash[:notice] = "Contact information for #{@customer.full_name} successfully updated."
      if ((newrole = params[:customer][:role])  &&
          newrole != @customer.role_name  &&
          current_user.can_grant(newrole))
        @customer.update_attribute(:role, Customer.role_value(newrole))
        flash[:notice] << "  Privilege level set to '#{newrole}.'"
      end
      Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => @customer.id,
        :logged_in_id => current_user.id,
        :comments => flash[:notice])
      if @customer.email_changed? && @customer.valid_email_address? &&
          params[:dont_send_email].blank? 
        # send confirmation email
        email_confirmation(:confirm_account_change,@customer, 
                           "updated your email address in our system")
      end
      redirect_after_login(@customer)
    rescue ActiveRecord::RecordInvalid
      flash[:notice] = ["Update failed: ", @customer, "Please fix error(s) and try again."]
      redirect_to edit_customer_path(@customer)
    rescue Exception => e
      flash[:notice] = "Update failed: #{e.message}"
      redirect_to edit_customer_path(@customer)
    end
  end

  def change_password_for
    return if request.get?
    if @customer.update_attributes(params[:customer])
      password = params[:customer][:password]
      flash[:notice] = "Changes confirmed."
      Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :comments => 'Change password')
      redirect_to customer_path(@customer)
    else
      render :action => 'change_password_for'
    end
  end

  def change_secret_question
    return if request.get?
    if @customer.update_attributes(params[:customer])
      Txn.add_audit_record(:txn_type => 'edit', :customer_id => @customer.id,
        :comments => 'Change secret question or answer')
      flash[:notice] = 'Secret question change confirmed.'
      redirect_to customer_path(@customer)
    else
      flash[:alert] = ["Could not update secret question: ", @customer]
      render :action => :change_secret_question, :id => @customer
    end
  end

  # actions NOT requiring @customer to be set
  def forgot_password
    return if request.get?
    if send_new_password(params[:email])
      redirect_to login_path
    else
      redirect_to forgot_password_customers_path
    end
  end

  def new
    @is_admin = current_user.is_boxoffice
    @customer = Customer.new
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
      email_confirmation(:confirm_account_change,@customer,"set up an account with us")
      Txn.add_audit_record(:txn_type => 'edit',
        :customer_id => @customer.id,
        :comments => 'new customer self-signup')
      create_session(@customer) # will redirect to next action
    rescue RuntimeError => e
      flash[:notice] = "There was a problem creating your account: #{e.message}."
      render :action => 'new'
    end
  end

  # Following actions are for use by admins only:
  # list, merge, search, create, destroy

  def index
    @list_type = :all
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
    render :action => 'index'
  end

  def list_duplicate
    @list_type = :duplicates
    @offset,@limit = get_list_params
    @customers = Customer.find_suspected_duplicates(@limit,@offset)
    @count = @customers.length
    @previous = [@offset - @limit, 0].max
    @next = @offset + [@limit,@count].min
    @title = "Suspected Duplicates #{@offset+1} - #{@offset+@count}"
    render :action => 'index'
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
      flash[:alert] = "At least one customer not found. Please try again."
      redirect_to_last_list and return
    end
    @offset = params[:offset]
    @last_action_name = params[:action_name]
    # automatic merge?
    case params[:commit]
    when /forget/i
      count = do_deletions(@cust, :forget!)
      flash[:notice] = "#{count} customers forgotten (their transactions have been preserved)<br/> #{flash[:notice]}"
      redirect_to_last_list and return
    when /expunge/i
      count = do_deletions(@cust, :expunge!)
      flash[:notice] = "#{count} customers (and their transactions) expunged<br/> #{flash[:notice]}"
      redirect_to_last_list and return
    when /auto/i
      do_automatic_merge(*params[:merge].keys)
      redirect_to_last_list and return
    when /manual/i
      render :action => 'merge'
    else
      flash[:alert] = "Unrecognized action: #{params[:commit]}"
      redirect_to_last_list and return
    end
  end

  def finalize_merge
    c0 = Customer.find_by_id(params.delete(:cust0))
    c1 = Customer.find_by_id(params.delete(:cust1))
    unless c0 && c1
      flash[:alert] = "At least one customer not found. Please try again."
      redirect_to_last_list and return
    end
    result = c0.merge_with_params!(c1, params)
    # result is nil if merge failed, else string describing result
    flash[:notice] = result || c0
    logger.info "Merging <#{c1}> into <#{c0}>: #{flash[:notice]}"
    redirect_to_last_list
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

  def create
    @is_admin = true            # needed for choosing correct method in 'new' tmpl
    @customer = Customer.new(params[:customer])
    @customer.created_by_admin = true
    render(:action => 'new') and return unless @customer.save
    (flash[:notice] ||= '') <<  'Account was successfully created.'
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => @customer.id,
      :comments => 'new customer added',
      :logged_in_id => current_user.id)
    # if valid email, send user a welcome message
    unless params[:dont_send_email]
      email_confirmation(:confirm_account_change,@customer,"set up an account with us")
    end
    redirect_to customer_path(@customer)
  end

  # AJAX helpers
  # auto-completion for customer search
  def auto_complete_for_customer_full_name
    render :inline => "" and return if params[:__arg].blank?
    @customers =
      Customer.find_by_multiple_terms(params[:__arg].to_s.split( /\s+/ ))
    render(:partial => 'customers/customer_search_result',
      :locals => {:matches => @customers})
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

  private

  def get_list_params
    offset = [params[:offset].to_i, 0].max
    limit = [params[:limit].to_i, 20].max
    return [offset,limit]
  end

  def do_deletions(customers, method)
    count = 0
    flash[:alert] = ''
    customers.each do |c|
      c.send(method)
      if c.errors.empty?
        count += 1
      else
        flash[:alert] << c
      end
    end
    count
  end

  def redirect_to_last_list
    redirect_to :action => (params[:action_name] || 'index'), :customers_filter => params[:customers_filter], :offset => params[:offset]
  end

  def do_automatic_merge(id0,id1)
    c0 = Customer.find_by_id(id0)
    c1 = Customer.find_by_id(id1)
    flash[:notice] ||= ''
    if c0.merge_automatically!(c1)
      flash[:notice] << "Successful merge"
    else
      flash[:notice] = ["Automatic merge failed, try merging manually to resolve the following errors:" , c0]
    end
  end

  private
 
  def delete_admin_only_attributes(params)
    Customer.extra_attributes.each { |a| params.delete(a) }
    params.delete(:comments)
    params
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
        "<br/>Please contact #{Option.help_email} if you need help."
      return nil
    end
  end

end
