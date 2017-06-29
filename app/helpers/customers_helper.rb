module CustomersHelper
  # Greeting for a customer
  def greet(customer)
    customer.first_name.blank? ? customer.full_name : customer.first_name
  end
  #
  # Link to user's home page
  #
  def link_to_customer(customer, options={})
    return '' unless customer
    content_text      = options.delete(:content_text) || customer.full_name
    link_to h(content_text), customer_path(customer), options
  end

  def existing_customer(customer)
    customer && !customer.new_record?
  end

  def format_collection_with_style(collection, css_class)
    # show a collection as a bunch of span's styled with css class
    collection.map do |elt|
      content_tag('span', h(elt), :class => css_class)
    end.join('').html_safe
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

  def rollover_with_contact_info(customer, attrib=:full_name)
    content_tag(:span, h(customer.send(attrib)), :class => 'customer_rollover', :title => ( [customer.email, customer.day_phone, customer.eve_phone].join(' ') rescue ''))
  end

  def roles_with_names
    Customer.roles.map { |r| [r.humanize, r] }
  end

  # staff person's name shown as "Armando F."

  def staff_name(cust)
    return content_tag('span', '???', :class => 'attention') if cust.nil?
    name = cust.special_customer? ? cust.first_name :
      "#{cust.first_name.name_capitalize} #{cust.last_name[0,1].upcase}."
    cust.is_staff ?  name : content_tag('span', name, :class => 'attention')
  end

  def number_to_phone_2(s)
    (!s.blank? && s.strip.match(/^([-0-9.()\/ ]{10,})([EXText.0-9]+)?$/) ?
      number_to_phone($1.gsub(/[^0-9]/,'').to_i, :delimiter=>'.') << h($2.to_s) :
      h(s))
  end

  def multiple_voucher_comments(vouchers)
    vouchers.map { |v| v.comments unless v.comments.blank? }.compact.join('; ')
  end
  
  def display_class(c)
    return 'invalid' unless c.valid?
    klass = []
    klass << 'staff' if  c.is_staff
    klass << 'subscriber' if c.subscriber?
    klass.join ' '
  end

  def secret_question_select(customer=Customer.generic_customer)
    ques = APP_CONFIG[:secret_questions]
    max = ques.length - 1
    idx = [max, customer.secret_question].min
    options_for_select(ques.zip((0..max).to_a), idx)
  end
  
  def secret_question_text(indx)
    (indx < 1 || indx > APP_CONFIG[:secret_questions].length) ? '' :
      APP_CONFIG[:secret_questions][indx]
  end

  def menu_or_static_text(name, num)
    if num > 1
      select_tag name, options_for_select((1..num), num)
    else
      content_tag('span', '1') + hidden_field_tag(name, 1)
    end
  end

end
