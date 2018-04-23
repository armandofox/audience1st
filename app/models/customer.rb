class Customer < ActiveRecord::Base

  acts_as_reportable
  
  require_dependency 'customer/special_customers'
  require_dependency 'customer/secret_question'
  require_dependency 'customer/scopes'
  require_dependency 'customer/birthday'
  require_dependency 'customer/merge'

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken


  require 'csv'

  has_and_belongs_to_many :labels
  has_many :vouchers, -> { includes(:vouchertype).order('created_at DESC') }
  has_many :vouchertypes, :through => :vouchers
  has_many :showdates, :through => :vouchers
  has_many :orders, -> { where( 'sold_on IS NOT NULL').order('sold_on DESC') }
  
  # nested has_many :through doesn't work in Rails 2, so we define a method instead
  # has_many :shows, :through => :showdates
  def shows ; self.showdates.map(&:show).uniq ; end

  has_many :txns
  has_one  :most_recent_txn, -> { order('txn_date DESC') }, :class_name=>'Txn'
  has_many :donations
  has_many :retail_items
  has_many :items               # the superclass of vouchers,donations,retail_items
  
  validates_format_of :email, :if => :self_created?, :with => /\A\S+@\S+\z/

  EMAIL_UNIQUENESS_ERROR_MESSAGE = 'has already been registered.'
  validates_uniqueness_of :email,
  :allow_blank => true,
  :case_sensitive => false,
  :message => EMAIL_UNIQUENESS_ERROR_MESSAGE

  def unique_email_error
    self.errors[:email].include? EMAIL_UNIQUENESS_ERROR_MESSAGE
  end
    
  validates_format_of :zip, :if => :self_created?, :with => /\A^[0-9]{5}-?([0-9]{4})?\z/, :allow_blank => true
  validate :valid_or_blank_address?, :if => :self_created?
  validate :valid_as_gift_recipient?, :if => :gift_recipient_only

  NAME_REGEX = /\A[-A-Za-z0-9_\/#\@'":;,.%\ ()&]+\z/
  NAME_FORBIDDEN_CHARS = /[^-A-Za-z0-9_\/#\@'":;,.%\ ()&]/
  
  BAD_NAME_MSG = "must not include special characters like <, >, !, etc."

  validates_length_of :first_name, :within => 1..50
  validates_format_of :first_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  validates_length_of :last_name, :within => 1..50
  validates_format_of :last_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  attr_accessor :validate_password
  validates_length_of :password, :on => :create, :if => :self_created?, :in => 1..20
  validates_length_of :password, :on => :update, :if => :validate_password, :in => 1..20
  validates_confirmation_of :password, :if => :self_created?

  

  attr_accessor :force_valid         
  attr_accessor :gift_recipient_only 
  attr_accessor :password

  attr_accessible :first_name, :last_name, :street, :city, :state, :zip,
  :day_phone, :eve_phone, :blacklist,  :email, :e_blacklist, :birthday,
  :password, :password_confirmation, :comments,
  :secret_question, :secret_answer,
  :company, :title, :company_url, :company_address_line_1,
  :company_address_line_2, :company_city, :company_state, :company_zip,
  :cell_phone, :work_phone, :work_fax, :best_way_to_contact


  cattr_reader :replaceable_attributes, :extra_attributes
  @@replaceable_attributes  =
    %w(first_name last_name email street city state zip day_phone eve_phone
        company title company_address_line_1 company_address_line_2 company_url
        company_city company_state company_zip work_phone cell_phone work_fax
        best_way_to_contact
)
  @@extra_attributes =
    [:company, :title, :company_address_line_1, :company_address_line_2,
     :company_city, :company_state, :company_zip, :work_phone, :cell_phone,
     :work_fax, :company_url]

  before_validation :force_valid_fields, :on => :create
  before_save :trim_whitespace_from_user_entered_strings
  after_save :update_email_subscription

  before_destroy :cannot_destroy_special_customers

  # Paginating customer list
  def self.per_page ;  20 ; end

  def active_vouchers
    now = Time.now
    vouchers.select { |v| now <= Time.at_end_of_season(v.season) }
  end
  

  #----------------------------------------------------------------------
  #  private variables
  #----------------------------------------------------------------------

  private

  def self_created? ; !created_by_admin && !gift_recipient_only ; end

  # for things like daemon-created customers, the force_valid flag will cause a customer
  # to be created with minimal valid fields so that saving cannot possibly fail validations.

  def force_valid_fields
    if self.force_valid
      self.created_by_admin = true # will skip most validations
      self.first_name = '_' if first_name.blank?
      self.first_name.gsub!(NAME_FORBIDDEN_CHARS, '_')
      self.last_name = '_' if last_name.blank?
      self.last_name.gsub!(NAME_FORBIDDEN_CHARS, '_')
      self.email = nil unless valid_and_unique(email)
    end
    true
  end
    
  def valid_and_unique(email)
    if email.blank?
      true 
    elsif !email.match(/^[\w\d]+@[\w\d]+/)
      false
    else
      !(Customer.where('email LIKE ?', email.downcase)).first
    end
  end

  # match up donation customer with an existing one, or create it
  def self.for_donation(params)
    customer_info = Customer.new params
    @customer =
      if (found_customer = Customer.find_unique(customer_info)) &&
          found_customer.valid_as_purchaser?
        # use this customer
        found_customer
      elsif customer_info.valid_as_purchaser?
        # create this customer
        Customer.find_or_create!(customer_info)
      else
        # invalid info given
        customer_info           # has failed validation as purchaser
      end
  end

  # address is allowed to be blank, but if nonblank, it must be valid
  def valid_or_blank_address?
    blank_mailing_address? || valid_mailing_address?
  end
  
  # when customer is saved, possibly update their email opt-in status
  # with external mailing list.  

  @@email_sync_disabled = nil
  def self.enable_email_sync ;  @@email_sync_disabled = nil ; end
  def self.disable_email_sync ; @@email_sync_disabled = true  ; end

  def update_email_subscription
    return unless (@@email_sync_disabled || e_blacklist_changed? || email_changed? || first_name_changed? || last_name_changed?)
    if e_blacklist      # opting out of email
      EmailList.unsubscribe(self, email_was)
    else                        # opt in
      if (email_changed? || first_name_changed? || last_name_changed?)
        if email_was.blank?
          EmailList.subscribe(self)
        else
          EmailList.update(self, email_was)
        end
      else                      # with same email
        EmailList.subscribe(self)
      end
    end
  end

  def encourage_opt_in_message
    if !(m = Option.encourage_email_opt_in).blank?
      m << '.' unless m =~ /[.!?:;,]$/
      m << ' Click the Billing/Contact tab (above) to update your preferences.'
      m
    else ''
    end
  end

  def welcome_message
    subscriber? ? Option.welcome_page_subscriber_message.to_s :
      Option.welcome_page_nonsubscriber_message.to_s
  end
  
  
  #----------------------------------------------------------------------
  #  public methods
  #----------------------------------------------------------------------

  public

  def self.id_from_route(route)
    # This should really use
    #  ActionController::Routing::Routes.recognize_path(route, :method => :get))[:Id]
    # to do the recognition, but it doesn't work in production because the production
    # server prepends the theater name /altarena or /ccct etc to the full route...ugh...
    # :BUG:
    route =~ /\/customers\/(-?\d+)$/ ? $1 : nil
  end
  
  # message that will appear in flash[:notice] once only, at login
  def login_message
    msg = ["Welcome, #{full_name}"]
    msg << encourage_opt_in_message if has_opted_out_of_email?
    msg << setup_secret_question_message unless has_secret_question?
    msg << welcome_message
    msg
  end

  def set_labels(labels_list)
    self.labels = (
      labels_list.respond_to?(:each) ?
      Label.all_labels.select { |l| labels_list.include?(l.id) } :
      [])
  end

  def update_labels!(hash)
    self.set_labels(hash)
    self.save! 
  end
  
  def valid_as_gift_recipient?
    # must have first and last name, mailing addr, and at least one
    #  phone or email
    valid = true
    if (first_name.blank? || last_name.blank?)
      errors.add :base,"First and last name must be provided"
      valid = false
    end
    if invalid_mailing_address?
      errors.add :base,"Valid mailing address must be provided for #{self.full_name}"
      valid = false
    end
    if day_phone.blank? && eve_phone.blank? && !valid_email_address?
      errors.add :base,"At least one phone number or email address must be provided for #{self.full_name}"
      valid = false
    end
    valid
  end

  def valid_as_purchaser?
    # must have full address and full name
    valid_mailing_address? && !first_name.blank? && !last_name.blank?
  end

  @@user_entered_strings =
    %w[first_name last_name street city state zip day_phone eve_phone  email]

  # strip whitespace before saving
  def trim_whitespace_from_user_entered_strings
    @@user_entered_strings.each do |col|
      c = self.send(col)
      c.send(:strip!) if c.kind_of?(String)
    end
  end

  # a convenient wrapper class for the ActiveRecord::sanitize_sql protected method

  def self.render_sql(sql)
    ActiveRecord::Base.sanitize_sql(sql)
  end

  # convenience accessors

  def to_s
    "[#{id}] #{full_name} " << (email.blank? ? '' : "<#{email}> ") 
  end

  def inspect
    self.to_s <<
      (street.blank? ? '' : " #{street}, #{city} #{state} #{zip} #{day_phone}")
  end
  
  def full_name
    "#{first_name.name_capitalize unless first_name.blank?} #{last_name.name_capitalize unless last_name.blank?}"
  end

  def full_name_with_id
    "#{self.id} [#{self.full_name}]"
  end

  def full_name_with_email
    valid_email_address? ? "#{full_name} (#{email})" : full_name
  end

  def sortable_name
    "#{self.last_name.downcase},#{self.first_name.downcase}"
  end

  def valid_email_address?
    !self.email.blank? && self.email.match(/^\S+@\S+/)
  end
  def invalid_email_address? ; !valid_email_address? ; end

  def has_opted_out_of_email? ;  e_blacklist? && valid_email_address?  end

  def valid_mailing_address?
    %w(street city state zip).each do |field|
      errors.add(field, "can't be blank") if self.send(field).blank?
    end
    errors.add(:zip, 'must be between 5 and 10 characters') if !zip.blank? && !zip.to_s.length.between?(5,10)
    errors.empty?
  end
  def invalid_mailing_address? ; !valid_mailing_address? ; end
  def blank_mailing_address?
    street.blank? && city.blank? && zip.blank?
  end

  def subscriber?
    self.role >= 0 &&
      self.vouchers.detect do |f|
      f.vouchertype.subscription? && f.vouchertype.valid_now?
    end
  end

  def next_season_subscriber?
    self.role >= 0 &&
      self.vouchers.detect do |f|
      f.vouchertype.subscription? &&
        f.vouchertype.expiration_date.within_season?(Time.now.at_end_of_season + 1.year)
    end
  end

  # add items to a customer's account - could be vouchers, record of a
  # donation, or purchased goods

  def add_items(items)
    self.items += items
  end

  def self.find_by_email_for_authentication(email)
    if email.blank?
      u = Customer.new
      u.errors.add(:login_failed, "Please provide your email and password.")
      return u
    end
    unless (u = Customer.where("email LIKE ?", email.downcase).first) # need to get the salt
      u = Customer.new
      u.errors.add(:login_failed, "Can't find that email in our database.  Maybe you signed up with a different one?  If not, click Create Account to create a new account.")
      return u
    end
  end

  def self.authenticate(email, password)
    if (email.blank? || password.blank?)
      u = Customer.new
      u.errors.add(:login_failed, "Please provide your email and password.")
      return u
    end
    unless (u = Customer.where("lower(email) LIKE ?", email.strip.downcase).first) # need to get the salt
      u = Customer.new
      u.errors.add(:login_failed, "Can't find that email in our database.  Maybe you signed up with a different one?  If not, click Create Account to create a new account.")
      return u
    end
    unless u.authenticated?(password)
      u.errors.add(:login_failed, "Password incorrect.  If you forgot your password, click 'Reset my password' and we will email you a new password within 1 minute.")
    end
    return u
  end

  # Values of the role field:
  # Roles are cumulative, ie higher privilege level can do everything
  # the lower levels can do.
  # < 10  regular user (customer)
  # at least 10 - board/staff member (can view/make reports, but not reservations)
  # at least 20 - box office user
  # at least 30 - box office manager
  # at least 100 - God ('admin')

  @@roles = [['patron', 0],
             ['staff', 10],
             ['walkup', 15],
             ['boxoffice', 20],
             ['boxoffice_manager', 30],
             ['admin', 100]]

  def self.role_value(role)
    r = role.to_s.downcase
    if (rr  = @@roles.assoc(r)) then rr.last else 100 end # fail-safe!!
  end

  def self.role_name(rval)
    @@roles.select { |r| r.last <= rval }.last.first
  end

  def role_name
    Customer.role_name(self.role)
  end

  def role_value
    Customer.role_value(self.role)
  end
  
  # you can grant someone else a particular role as long as it's less
  # than your own.

  def can_grant(newrole)
    # TBD should really check that the two are
    # in different role-equivalence classes
    self.role >= Customer.role_value(newrole)
  end

  def self.can_ignore_cutoff?(id)
    Customer.find(id).is_walkup
  end

  def self.roles
    @@roles.map {|x| x.first}
  end

  def self.nobody_id
    0
  end

  # a generic customer who is a 'stand in' for determining customer
  # privileges; the least common denominator
  def self.generic_customer
    Customer.walkup_customer
    # for now, same as the 'walkup customer'
  end

  public

  @@roles.each do |r|
    role = r.first
    lvl = r.last
    eval "def is_#{role}; self.role >= #{lvl}; end"
  end

  def self.find_suspected_duplicates
    # similarity: last names must match, emails must not differ,
    #  and at least one of first name or street must match.
    sql = <<EOSQL1
      SELECT DISTINCT c1.*
      FROM customers c1 INNER JOIN customers c2 ON c1.last_name=c2.last_name
      WHERE c1.id != c2.id AND
        (c1.email LIKE c2.email OR c1.email IS NULL OR c2.email IS NULL) AND
        (c1.first_name LIKE c2.first_name OR
          (c1.street LIKE c2.street AND c1.street IS NOT NULL AND c1.street != ''))
      ORDER BY c1.last_name,c1.first_name
EOSQL1
    possible_dups = Customer.find_by_sql(sql)
  end

  # given some customer info, find this customer in the database with
  # high confidence;  if not found or ambiguous, return nil

  def self.find_unique(p)
    return (
      match_email_and_last_name(p.email, p.last_name) ||
      match_first_last_and_address(p.first_name, p.last_name, p.street) ||
      (p.street.blank? ? match_uniquely_on_names_only(p.first_name, p.last_name) : nil)
      )
  end



  # If customer can be uniquely identified in DB, return match from DB
  # and fill in blank attributes with nonblank values from provided attrs.
  # Otherwise, create new customer.

  def self.find_or_create!(cust, loggedin_id=0)
    if (c = Customer.find_unique(cust))
      Rails.logger.info "Copying nonblank attribs for unique #{cust}\n from #{c}"
      c.copy_nonblank_attributes(cust)
      c.created_by_admin = true # ensure some validations are skipped
      txn = "Customer found and possibly updated"
    else
      c = cust
      Rails.logger.info "Creating customer #{cust}"
      txn = "Customer not found, so created"
    end
    c.force_valid = true      # make sure will pass validation checks
    # precaution: make sure email is unique.
    c.email = nil if (!c.email.blank? &&
      Customer.where('email like ?',c.email.downcase).first)
    c.save!
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => c.id,
      :comments => txn,
      :logged_in_id => loggedin_id)
    c
  end

  # case-insensitive find by first & last name.  if multiple terms given,
  # all must match, though each term can match either first or last name
  def self.find_by_multiple_terms(terms)
    return [] if terms.empty?
    conds_ary = []
    cols = %w(first_name last_name street city zip day_phone eve_phone comments company email)
    conds = cols.map { |c| "(lower(#{c}) LIKE ?)" }.join(" OR ")
    terms.each do |term|
      conds_ary = Array.new(cols.size) { "%#{term.downcase}%" }.concat(conds_ary)
    end
    conds = Array.new(terms.size, conds).map{ |cond| "(#{cond})"}.join(" AND ")
    conds_ary.unshift(conds)
    Customer.where(conds_ary).limit(50).order("last_name").take(10)
  end

  # return a hash include information containing searching term in auto
  # complete
  def self.find_by_terms_col(terms)
    return [] if terms.empty?
    customers =
        Customer.find_by_multiple_terms(terms).
            reject {|customer| Customer.find_by_name(terms).include?(customer)}
    col_hash = Hash.new
    customers.each do |customer|
      col_hash[customer] = self.match_attr_info(customer, terms)
    end
    col_hash
  end

  # find info containing seaching terms in an object
  def self.match_attr_info(customer,terms)
    matching_info = ''
    Customer.column_names.reject{ |col|
      (%w[role crypted_password salt _at$ _on$]).include? col}.each do |col|
      terms.each do |term|
        if (customer.attributes[col].is_a? String) &&
            customer.attributes[col].downcase.include?(term.downcase) &&
            (not matching_info.downcase.include?(customer.attributes[col].downcase))
          matching_info += " (#{customer[col]})"
          next
        end
      end
    end

    matching_info
  end

  # method find customers whose name containing the searching term
  def self.find_by_name(terms)
    conds =
        Array.new(terms.length, "(lower(first_name) LIKE ? or lower(last_name) LIKE ?)").join(' AND ')
    conds_ary = terms.map { |w| ["%#{w.downcase}%", "%#{w.downcase}%"] }.flatten.unshift(conds)
    Customer.where(*conds_ary).order('last_name').take(10)
  end

  # Override content_columns method to omit password hash and salt
  def self.content_columns
    super.delete_if { |x| x.name.match(%w[role crypted_password salt _at$ _on$].join('|')) }
  end

  def self.address_columns
    self.content_columns.select {
      |x| x.name.match('first_name|last_name|street|city|state|zip')
    }
  end

  # Convert list of customers to CSV.  If with_errors is true, last column is
  # ActiveRecord error messages for the customer (joined with ';').

  def self.to_csv(custs,opts={})
    CSV::Writer.generate(output='') do |csv|
      unless opts[:suppress_header]
        header = ['First name', 'Last name', 'Email', 'Street', 'City', 'State', 'Zip',
          'Day/main phone', 'Eve/alt phone', "Don't mail", "Don't email"]
        header += opts[:extra].map(&:humanize) if opts[:extra]
        csv << header
      end
      custs.each do |c|
        row = c.to_csv
        opts[:extra].each { |attrib|  row << c.send(attrib) }
        row << c.errors.full_messages.join('; ') if opts[:include_errors]
        csv << row
      end
      return output
    end
  end

  def to_csv
    [
      (first_name.name_capitalize unless first_name.blank?),
      (last_name.name_capitalize unless last_name.blank?),
      email,
      street,city,state,zip,
      day_phone, eve_phone,
      (blacklist ? "true" : ""),
      (e_blacklist ? "true" : "")
    ]
    
  end

  # support for find_unique

  def self.match_email_and_last_name(email,last_name)
    !email.blank? && !last_name.blank? &&
      Customer.where('email LIKE ? AND last_name LIKE ?', email.strip, last_name.strip).first
  end

  def self.match_first_last_and_address(first_name,last_name,street)
    !first_name.blank? && !last_name.blank? && !street.blank? &&
      Customer.where('first_name LIKE ? AND last_name LIKE ? AND street like ?', first_name, last_name, street).first
  end

  def self.match_uniquely_on_names_only(first_name, last_name)
    return nil if first_name.blank? || last_name.blank?
    m = Customer.where('last_name LIKE ? AND first_name LIKE ?',  last_name, first_name)
    m && m.length == 1 ?  m.first : nil
  end
end


