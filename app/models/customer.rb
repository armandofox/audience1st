class Customer < ActiveRecord::Base

  require_dependency 'customer/roles'
  require_dependency 'customer/search'
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
  has_many :vouchers, -> { includes(:vouchertype).order(:created_at => :desc) }
  has_many :vouchertypes, :through => :vouchers
  has_many :showdates, :through => :vouchers
  has_many :orders, -> { where( 'sold_on IS NOT NULL').order(:sold_on => :desc) }

  # nested has_many :through doesn't work in Rails 2, so we define a method instead
  # has_many :shows, :through => :showdates
  def shows ; self.showdates.map(&:show).uniq ; end

  has_many :txns
  has_one  :most_recent_txn, -> { order('txn_date DESC') }, :class_name=>'Txn'
  has_many :donations
  has_many :retail_items
  has_many :items               # the superclass of vouchers,donations,retail_items

  # There are multiple 'flavors' of customers with different validation requirements.
  # These should be factored out into subclasses.
  # | Type            | When used                    | Validations                                  |
  # | Customer (base) |                              |                                              |
  # | SelfCreated     | signup; edit info; change pw | All                                          |
  # | GuestCheckout   | guest checkout               | nonblank email,first,last,address            |
  # | GiftRecipient   | giftee of someone else       | nonblank first,last; nonblank email OR phone |
  # | Imported        | import from 3rd party        | none, but all fields FORCED valid on create  |


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

  NAME_REGEX = /\A[-A-Za-z0-9_\/#\@'":;,.%\ ()&]*\z/
  NAME_FORBIDDEN_CHARS = /[^-A-Za-z0-9_\/#\@'":;,.%\ ()&]/

  BAD_NAME_MSG = "must not include special characters like <, >, !, etc."

  validates_length_of :first_name, :within => 1..50
  validates_format_of :first_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  validates_length_of :last_name, :within => 1..50
  validates_format_of :last_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  attr_accessor :must_revalidate_password

  validates :password, :length => {:in => 3..20}, :on => :create, :if => :self_created?
  validates :password, :length => {:in => 3..20}, :on => :update, :if => :must_revalidate_password

  validates_confirmation_of :password, :on => :create,  :unless => :created_by_admin
  validates_confirmation_of :password, :on => :update,  :if => :must_revalidate_password

  attr_accessor :force_valid
  attr_accessor :gift_recipient_only
  attr_accessor :password
  attr_accessor :save_address_info

  attr_accessible :first_name, :last_name, :street, :city, :state, :zip,
  :day_phone, :eve_phone, :blacklist,  :email, :e_blacklist, :birthday,
  :password, :password_confirmation, :token, :token_created_at, :comments,
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

  def active_vouchers
    now = Time.current
    vouchers.
      includes(:showdate => :show).
      includes(:vouchertype => :valid_vouchers).
      select { |v| now <= Time.at_end_of_season(v.season) }
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
  # NOTE: This is an after-save hook, so customer is guaranteed to exist in database.
  def update_email_subscription
    return unless (e_blacklist_changed? || email_changed? || first_name_changed? || last_name_changed?)
    email_list = EmailList.new or return
    if e_blacklist      # opting out of email
      # do nothing, EXCEPT in the case where customer is transitioning from opt-in to opt-out,
      # AND they have a in which case unsubscribe them
      if !e_blacklist_was and !email_was.blank?
        email_list.unsubscribe(self, email_was)
      end
    else                        # opt in
      if (email_changed? || first_name_changed? || last_name_changed?)
        if email_was.blank?
          email_list.subscribe(self)
        elsif email.blank?
          email_list.unsubscribe(self, email_was)
        else
          email_list.update(self, email_was)
        end
      else                      # with same email
        email_list.subscribe(self)
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
    (Rails.application.routes.recognize_path(route))[:id]
  end

  # message that will appear in flash[:notice] once only, at login
  def login_message
    msg = ["Welcome, #{full_name}"]
    msg << encourage_opt_in_message if has_opted_out_of_email?
    msg << I18n.t('login.setup_secret_question_message') unless has_secret_question?
    msg << welcome_message
    msg
  end

  def has_ever_logged_in?
    last_login > Time.zone.parse('2007-04-07') # sentinel date should match what's in schema.rb
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

  def valid_as_guest_checkout?
    if (first_name.blank? || last_name.blank? || email.blank? || street.blank? || city.blank? || state.blank? || zip.blank?)
      errors.add :base, "Please provide your email address for order confirmation, and your credit card billing name and address."
      false
    else
      # this is a HACK: set created_by_admin to bypass most other validations.
      # This will be fixed when Customer class is refactored into subclasses with their own validations
      self.created_by_admin = true
      true
    end
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
      self.vouchers.includes(:vouchertype).detect do |f|
      f.vouchertype.subscription? && f.vouchertype.valid_now?
    end
  end

  def next_season_subscriber?
    self.role >= 0 &&
      self.vouchers.includes(:vouchertype).detect do |f|
      f.vouchertype.subscription? &&
        f.vouchertype.expiration_date.within_season?(Time.current.at_end_of_season + 1.year)
    end
  end

  # add items to a customer's account - could be vouchers, record of a
  # donation, or purchased goods

  def add_items(new_items)
    self.items << new_items
    # new_items.each { |i| i.customer_id = self.id }
    # self.items += new_items # <= doesn't work because cardinality of self.items is huge
  end

  def self.lookup_by_email_for_auth(email)
    Customer.where("lower(email) = ?", email.strip.downcase).first
  end

  def self.authenticate(email, password)
    if (email.blank? || password.blank?)
      u = Customer.new
      u.errors.add(:login_failed, I18n.t('login.email_or_password_blank'))
      return u
    end
    unless (u = Customer.lookup_by_email_for_auth(email)) # need to get the salt
      u = Customer.new
      u.errors.add(:login_failed, I18n.t('login.no_such_email'))
      return u
    end
    unless u.authenticated?(password)
      u.errors.add(:login_failed, I18n.t('login.bad_password'))
    end
    return u
  end


  def self.can_ignore_cutoff?(id)
    Customer.find(id).is_walkup
  end

  public

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

  def name_and_address_to_csv
    [
      (first_name.name_capitalize unless first_name.blank?),
      (last_name.name_capitalize unless last_name.blank?),
      email,
      street,city,state,zip
    ]
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

end
