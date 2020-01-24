module CustomersHelper
  # Greeting for a customer
  def greet(customer)
    return "Customer" if customer.nil?
    customer.first_name.blank? ? customer.full_name : customer.first_name
  end
  #
  # When did customer last login, if ever?
  #
  def last_login_for(customer)
    customer.has_ever_logged_in? ? customer.last_login.to_formatted_s(:showtime_including_year) : 'Never'
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

  def display_class(c)
    return 'invalid' unless c.valid?
    klass = []
    klass << 'staff' if  c.is_staff
    klass << 'subscriber' if c.subscriber?
    klass.join ' '
  end

  def secret_question_select(customer=Customer.walkup_customer)
    ques = I18n.t("app_config.secret_questions")
    max = ques.length - 1
    idx = [max, customer.secret_question].min
    options_for_select(ques.zip((0..max).to_a), idx)
  end
  
  def secret_question_text(indx)
    ques = I18n.t("app_config.secret_questions")
    (indx < 1 || indx > ques.length) ? '' : ques[indx]
  end

  def menu_or_static_text(name, group, html_opts={})
    num = group.size
    if num == 1 || group.has_reserved_seating
      content_tag('span', num) + hidden_field_tag(name, num, html_opts)
    else
      select_tag name, options_for_select((1..num), num), html_opts
    end
  end
  
end
