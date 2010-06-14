module CustomersHelper

  #---- these methods clipped from restful_authentication users helper
  
  #
  # Use this to wrap view elements that the user can't access.
  # !! Note: this is an *interface*, not *security* feature !!
  # You need to do all access control at the controller level.
  #
  # Example:
  # <%= if_authorized?(:index,   User)  do link_to('List all users', users_path) end %> |
  # <%= if_authorized?(:edit,    @user) do link_to('Edit this user', edit_user_path) end %> |
  # <%= if_authorized?(:destroy, @user) do link_to 'Destroy', @user, :confirm => 'Are you sure?', :method => :delete end %> 
  #
  #
  def if_authorized?(action, resource, &block)
    if authorized?(action, resource)
      yield action, resource
    end
  end

  #
  # Link to user's home page
  #
  def link_to_customer(customer, options={})
    raise "Invalid user" unless customer
    content_text      = options.delete(:content_text) || customer.full_name
    link_to h(content_text), {:controller => 'customers', :action => 'welcome'}, options
  end

  #
  # Link to login page using remote ip address as link content
  #
  # The :title (and thus, tooltip) is set to the IP address 
  #
  # Examples:
  #   link_to_login_with_IP
  #   # => <a href="/login" title="169.69.69.69">169.69.69.69</a>
  #
  #   link_to_login_with_IP :content_text => 'not signed in'
  #   # => <a href="/login" title="169.69.69.69">not signed in</a>
  #
  def link_to_login_with_IP content_text=nil, options={}
    ip_addr           = request.remote_ip
    content_text    ||= ip_addr
    options.reverse_merge! :title => ip_addr
    if tag = options.delete(:tag)
      content_tag tag, h(content_text), options
    else
      link_to h(content_text), login_path, options
    end
  end

  #
  # Link to the current user's page (using link_to_customer) or to the login page
  # (using link_to_login_with_IP).
  #
  def link_to_current_user(options={})
    if current_user
      link_to_customer current_user, options
    else
      content_text = options.delete(:content_text) || 'not signed in'
      # kill ignored options from link_to_customer
      [:content_method, :title_method].each{|opt| options.delete(opt)} 
      link_to_login_with_IP content_text, options
    end
  end

  #--- end stuff from restful_authentication

  def number_to_phone_2(s)
    (!s.blank? && s.strip.match(/^([-0-9.()\/ ]{10,})([EXText.0-9]+)?$/) ?
     number_to_phone($1.gsub(/[^0-9]/,'').to_i, :delimiter=>'.') << h($2.to_s) :
     h(s))
  end

  def multiple_voucher_comments(vouchers)
    vouchers.map { |v| v.comments unless v.comments.blank? }.compact.join('; ')
  end
  
  def display_class(c)
    klass = []
    if !c.valid?
      klass << 'invalid'
      return
    end
    klass << 'staff' if  c.is_staff
    klass << 'subscriber' if c.subscriber?
    klass.join ' '
  end

  def group_subscriber_vouchers(v1,v2)
    # each of v1 and v2 is an array of [showdate,vouchertype].
    # showdate is nil for open voucher.
    # this function is used to "sort" them for presenting on customer
    # welcome page.
    # VOuchers for SAME SHOW (ie, same vouchertype) stay together
    # Within a show category, OPEN VOUCHERS are listed last, others
    # are shown by order of showdate
    # vouchers for DIFFERENT SHOWS are ordered by opening date of the show
    sd1,vt1 = v1
    sd2,vt2 = v2
    if vt1 != vt2
      (vt1.showdates.min <=> vt2.showdates.min) rescue -1
    else
      (sd1 <=> sd2) rescue -1
    end
  end

end
