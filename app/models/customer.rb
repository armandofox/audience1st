class Customer < ActiveRecord::Base
  require_dependency 'customer/special_customers'
  require_dependency 'customer/secret_question'
  require_dependency 'customer/scopes'
  require_dependency 'customer/birthday'
  require_dependency '../lib/date_time_extras'

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  require 'csv'

  has_and_belongs_to_many :labels
  has_many :vouchers, :include => :vouchertype, :order => 'sold_on DESC'
  has_many :vouchertypes, :through => :vouchers
  has_many :showdates, :through => :vouchers
  has_many :orders
  
  # nested has_many :through doesn't work in Rails 2, so we define a method instead
  # has_many :shows, :through => :showdates
  def shows ; self.showdates.map(&:show).uniq ; end

  has_many :txns
  has_one  :most_recent_txn, :class_name=>'Txn', :order=>'txn_date DESC'
  has_many :donations

  has_many :visits
  has_one :most_recent_visit, :class_name => 'Visit', :order=>'thedate DESC'
  has_one :next_followup, :class_name => 'Visit', :order => 'followup_date'

  validates_format_of :email, :if => :self_created?, :with => Authentication.email_regex
  validates_uniqueness_of :email,
  :allow_blank => true,
  :case_sensitive => false,
  :message => "address {{value}} has already been registered.
    <a href='/login?email={{value}}'>Sign in with this email address</a>
    (if you forgot your password, use the 'Forgot your password?' link on sign-in page)"
  
  validates_format_of :zip, :if => :self_created?, :with => /^[0-9]{5}-?([0-9]{4})?$/, :allow_blank => true
  validate :valid_or_blank_address?, :if => :self_created?
  validate :valid_as_gift_recipient?, :if => :gift_recipient_only

  NAME_REGEX = /^[-A-Za-z0-9_\/#\@'":;,.%\ ()&]+$/
  NAME_FORBIDDEN_CHARS = /[^-A-Za-z0-9_\/#\@'":;,.%\ ()&]/
  
  BAD_NAME_MSG = "must not include special characters like <, >, !, etc."

  validates_length_of :first_name, :within => 1..50
  validates_format_of :first_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  validates_length_of :last_name, :within => 1..50
  validates_format_of :last_name, :with => NAME_REGEX,  :message => BAD_NAME_MSG

  validates_length_of :password, :if => :self_created_and_not_linked_to_facebook, :in => 4..20, :allow_nil => true
  validates_confirmation_of :password, :if => :self_created_and_not_linked_to_facebook

  attr_protected :id, :salt, :role, :created_by_admin
  attr_accessor :force_valid          ;  attr_protected :force_valid
  attr_accessor :gift_recipient_only  ;  attr_protected :gift_recipient_only
  attr_accessor :password

  cattr_reader :replaceable_attributes, :extra_attributes
  @@replaceable_attributes  =
    %w(first_name last_name email street city state zip day_phone eve_phone
        company title company_address_line_1 company_address_line_2 company_url
        company_city company_state company_zip work_phone cell_phone work_fax
        best_way_to_contact
)
  @@extra_attributes =
    [:referred_by_id, :referred_by_other, 
     :company, :title, :company_address_line_1, :company_address_line_2,
     :company_city, :company_state, :company_zip, :work_phone, :cell_phone,
     :work_fax, :company_url]

  before_validation_on_create :force_valid_fields
  before_save :trim_whitespace_from_user_entered_strings
  after_save :update_email_subscription

  before_destroy :cannot_destroy_special_customers

  def active_vouchers
    now = Time.now
    vouchers.select { |v| now <= Time.at_end_of_season(v.season) }
  end
  

  #----------------------------------------------------------------------
  #  private variables
  #----------------------------------------------------------------------

  private

  def self_created? ; !created_by_admin && !gift_recipient_only ; end

  def self_created_and_not_linked_to_facebook
    self_created? && !facebook_user?
  end

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
    elsif !email.match(Authentication.email_regex) 
      false
    else
      !(Customer.find_by_email email)
    end
  end

  # address is allowed to be blank, but if nonblank, it must be valid
  def valid_or_blank_address?
    errors.add_to_base "Mailing address must include street, city, state, Zip" unless (valid_mailing_address? || blank_mailing_address?)
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
    if !(m = Option.value(:encourage_email_opt_in)).blank?
      m << '.' unless m =~ /[.!?:;,]$/
      m << ' Click the Billing/Contact tab (above) to update your preferences.'
      m
    else ''
    end
  end

  def setup_secret_question_message
    'You can now setup a secret question to verify your identity in case you forget your password.  Click Change Password above to setup your secret question.'
  end

  def welcome_message
    subscriber? ? Option.value(:welcome_page_subscriber_message).to_s :
      Option.value(:welcome_page_nonsubscriber_message).to_s
  end
  
  
  #----------------------------------------------------------------------
  #  public methods
  #----------------------------------------------------------------------

  public
  
  # message that will appear in flash[:notice] once only, at login
  def login_message
    msg = ["Welcome, #{full_name.name_capitalize}"]
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
      errors.add_to_base "First and last name must be provided"
      valid = false
    end
    if invalid_mailing_address?
      errors.add_to_base "Valid mailing address must be provided"
      valid = false
    end
    if day_phone.blank? && eve_phone.blank? && !valid_email_address?
      errors.add_to_base "At least one phone number or email address must be provided"
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
    "[#{id}] #{full_name} " <<
      (email.blank? ? '' : "<#{email}> ") <<
      (fb_user_id.blank? ? '' : "{#{fb_user_id}}")
  end

  def inspect
    self.to_s <<
      (street.blank? ? '' : " #{street}, #{city} #{state} #{zip}")
  end
  
  def full_name
    "#{first_name.name_capitalize unless first_name.blank?} #{last_name.name_capitalize unless last_name.blank?}"
  end

  def full_name_with_id
    "#{self.id} [#{self.full_name}]"
  end
  
  def sortable_name
    "#{self.last_name.downcase},#{self.first_name.downcase}"
  end

  def valid_email_address?
    !self.email.blank? &&
      self.email.match(Authentication.email_regex)
  end
  def invalid_email_address? ; !valid_email_address? ; end

  def has_opted_out_of_email? ;  e_blacklist? && valid_email_address?  end

  def valid_mailing_address?
    !street.blank? &&
      !city.blank?  &&
      !state.blank? &&
      !zip.blank? &&
      zip.to_s.length.between?(5,10)
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


  def referred_by_name(maxlen=1000)
    if (c = Customer.find_by_id(self.referred_by_id.to_i))
      c.full_name[0..maxlen-1]
    else
      self.referred_by_other.to_s[0..maxlen-1]
    end
  end

  # add items to a customer's account - could be vouchers, record of a
  # donation, or purchased goods

  def add_items(items, logged_in, howpurchased=Purchasemethod.get_type_by_name('web_cc'), comment='')
    status = true
    items.map do |v|
      if v.kind_of?(Voucher)
        v.processed_by_id = logged_in
        v.purchasemethod = howpurchased
        success,msg = v.add_to_customer(self)
        if success
          Txn.add_audit_record(:txn_type => 'tkt_purch',
                               :customer_id => self.id,
                               :voucher_id => v.id,
                               :comments => comment,
                               :logged_in_id => logged_in,
                               :showdate_id => (v.showdate.id rescue 0),
                               :show_id => (v.showdate.show.id rescue 0),
                               :dollar_amount => v.vouchertype.price,
                               :purchasemethod_id => howpurchased.id)
        else
          status = nil
          logger.error "Error adding voucher #{v} to customer #{self.full_name_with_id}:  #{msg}"
          raise "Error: #{msg}"
        end
      elsif v.kind_of?(Donation)
        self.donations << v
        Txn.add_audit_record(:txn_type => 'don_cash',
                             :customer_id => self.id,
                             :comments => comment,
                             :logged_in_id => logged_in,
                             :dollar_amount => v.amount,
                             :purchasemethod_id => howpurchased)
      else
        logger.error "Can't add this product type to customer record: #{v}"
        raise "Can't add this product type to customer record"
      end
      v.id
    end
    return status
  end

  def self.find_by_email_for_authentication(email)
    if email.blank?
      u = Customer.new
      u.errors.add(:login_failed, "Please provide your email and password.")
      return u
    end
    unless (u = Customer.find(:first, :conditions => ["email LIKE ?", email.downcase])) # need to get the salt
      u = Customer.new
      u.errors.add(:login_failed, "Can't find that email in our database.  Maybe you signed up with a different one?  If not, click Create Account to create a new account, or Login With Facebook to login with your Facebook ID.")
      return u
    end
  end

  def self.authenticate(email, password)
    if (email.blank? || password.blank?)
      u = Customer.new
      u.errors.add(:login_failed, "Please provide your email and password.")
      return u
    end
    unless (u = Customer.find(:first, :conditions => ["email LIKE ?", email.downcase])) # need to get the salt
      u = Customer.new
      u.errors.add(:login_failed, "Can't find that email in our database.  Maybe you signed up with a different one?  If not, click Create Account to create a new account, or Login With Facebook to login with your Facebook ID.")
      return u
    end
    unless u.authenticated?(password)
      u.errors.add(:login_failed, "Password incorrect.  If you forgot your password, click 'Forgot your password?' and we will email you a new password within 1 minute.")
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

  def self.find_suspected_duplicates(limit=20,offset=1)
    limit = 20 if limit.to_i < 2
    sim = []
    sim << 'c1.first_name LIKE c2.first_name'
    
    # similarity: last names must match, emails must not differ,
    #  and at least one of first name or street must match.
    sql = <<EOSQL1
      SELECT DISTINCT c1.*
      FROM customers c1 INNER JOIN customers c2 ON c1.last_name=c2.last_name
      WHERE c1.id != c2.id AND
        (c1.email LIKE c2.email OR c1.email IS NULL OR c2.email IS NULL) AND
        (c1.first_name LIKE c2.first_name OR c1.street LIKE c2.street)
      ORDER BY c1.last_name,c1.first_name
      LIMIT #{limit}
      OFFSET #{offset}
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

  # under what circumstances do we consider a customer's name "the same" as a given first/last?
  def name_word_matches(ours,given)
    ours == given ||
      ours[0,1] == given.gsub(/[^A-Za-z]/,'') ||
      given[0,1] == ours.gsub(/[^A-Za-z]/,'')
  end
  def name_matches(first,last)
    our_first = self.first_name.to_s.downcase
    our_last = self.last_name.to_s.downcase
    first.to_s.downcase!
    last.to_s.downcase!
    return nil if (first.blank? && last.blank? && our_first.blank? && our_last.blank?)
    return (our_last == last) &&
      (name_word_matches(our_first, first) || our_first.blank? || first.blank?)
  end

  def copy_nonblank_attributes(from)
    Customer.replaceable_attributes.each do |attr|
      if !(val = from.send(attr)).blank?
        self.send("#{attr}=", val)
      end
    end
  end

  # If customer can be uniquely identified in DB, return match from DB
  # and fill in blank attributes with nonblank values from provided attrs.
  # Otherwise, create new customer.

  def self.find_or_create!(cust, loggedin_id=0)
    if (c = Customer.find_unique(cust))
      logger.info "Copying nonblank attribs for unique #{cust}\n from #{c}"
      c.copy_nonblank_attributes(cust)
      c.created_by_admin = true # ensure some validations are skipped
      txn = "Customer found and possibly updated"
    else
      c = cust
      logger.info "Creating customer #{cust}"
      txn = "Customer not found, so created"
    end
    c.force_valid = true      # make sure will pass validation checks
    # precaution: make sure email is unique.
    c.email = nil if (!c.email.blank? &&
      Customer.find(:first,:conditions => ['email like ?',c.email]))
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
    conds =
      Array.new(terms.length, "(first_name LIKE ? or last_name LIKE ?)").join(' AND ')
    conds_ary = terms.map { |w| ["%#{w}%", "%#{w}%"] }.flatten.unshift(conds)
    Customer.find(:all, :conditions => conds_ary, :order =>'last_name')
  end

  
  # Match on any content column of a class

  def self.match_any_content_column(string)
    cols = self.content_columns
    a = Array.new(cols.size) { "%#{string}%" }
    a.unshift(cols.map { |c| "(#{c.name} LIKE ?)" }.join(" OR "))
  end

    

  # Override content_columns method to omit password hash and salt
  def self.content_columns
    super.delete_if { |x| x.name.match(%w[role oldid crypted_password salt _at$ _on$].join('|')) }
  end

  def self.address_columns
    self.content_columns.select {
      |x| x.name.match('first_name|last_name|street|city|state|zip')
    }
  end

  # Convert list of customers to CSV.  If with_errors is true, last column is
  # ActiveRecord error messages for the customer (joined with ';').

  def self.to_csv(custs,opts={})
    filenm = custs.first.class.to_s.downcase
    CSV::Writer.generate(output='') do |csv|
      unless opts[:suppress_header]
        header = ['First name', 'Last name', 'Email', 'Street', 'City', 'State', 'Zip',
          'Day/main phone', 'Eve/alt phone', "Don't mail", "Don't email"]
        header += opts[:extra] if opts[:extra]
        csv << header
      end
      custs.each do |c|
        row = [
          (c.first_name.name_capitalize unless c.first_name.blank?),
          (c.last_name.name_capitalize unless c.last_name.blank?),
          c.email,
          c.street,c.city,c.state,c.zip,
          c.day_phone, c.eve_phone,
          (c.blacklist ? "true" : ""),
          (c.e_blacklist ? "true" : "")
        ]
        opts[:extra].each { |attrib|  row << c.send(attrib) }
        row << c.errors.full_messages.join('; ') if opts[:include_errors]
        csv << row
      end
      return output
    end
  end


  def self.find_all_subscribers(order_by='last_name',opts={})
    from = Time.now.at_beginning_of_season.to_formatted_s(:db)
    to = Time.now.at_end_of_season.to_formatted_s(:db)
    conds = ['vt.subscription=1',
      "#{Time.db_now} BETWEEN '#{from}' AND '#{to}'"]
    conds.push('(c.e_blacklist IS NULL OR c.e_blacklist=0)') if
      opts[:exclude_e_blacklist]
    conds.push('(c.blacklist IS NULL OR c.blacklist=0)') if
      opts[:exclude_blacklist]

    Customer.find_by_sql("SELECT DISTINCT c.* " <<
                         " FROM customers c JOIN items v ON v.customer_id=c.id " <<
                         " JOIN vouchertypes vt on v.vouchertype_id=vt.id " <<
                         " WHERE v.type='Voucher' AND " <<
                         conds.join(' AND ') <<
                         " ORDER BY #{order_by}")
  end


  def self.find_by_fb_user(fb_user)
    ((!fb_user.uid.blank? && Customer.find_by_fb_user_id(fb_user.uid)) ||
      (!fb_user.email_hashes.blank? && Customer.find_by_email_hash(fb_user.email_hashes)))
  end

  # Take the data returned from facebook and create a new user from it.
  # We don't get the email from Facebook and because a facebooker can only login through Connect we just generate a unique login name for them.
  # If you were using username to display to people you might want to get them to select one after registering through Facebook Connect
  if USE_FACEBOOK
    def self.create_from_fb_connect(fb_user)
      first_name,last_name = fb_user.name.first_and_last_from_full_name
      logger.info "Creating new '#{first_name} #{last_name}' for FB id #{fb_user.id}"
      new_facebooker = Customer.new(:first_name => first_name,
        :last_name => last_name,
        :password => "", :email => "")
      new_facebooker.fb_user_id = fb_user.uid.to_i
      #We need to save without validations
      new_facebooker.save(false)
      new_facebooker.register_user_to_fb
      new_facebooker
    end

    #We are going to connect this user object with a facebook id. But only ever one account.
    def link_fb_connect(fb_user_id)
      logger.info "Linking FB userid #{fb_user_id} to current user"
      unless fb_user_id.nil?
        #check for existing account
        existing_fb_user = Customer.find_by_fb_user_id(fb_user_id)
        #unlink the existing account
        unless existing_fb_user.nil?
          existing_fb_user.fb_user_id = nil
          existing_fb_user.save(false)
        end
        #link the new one
        self.fb_user_id = fb_user_id
        save(false)
      end
    end

    #The Facebook registers user method is going to send the users email hash and our account id to Facebook
    #We need this so Facebook can find friends on our local application even if they have not connect through connect
    #We then use the email hash in the database to later identify a user from Facebook with a local user
    def register_user_to_fb
      if !email.blank?
        begin
          users = {:login => email, :account_id => id}
          Facebooker::User.register([users])
          self.email_hash = Facebooker::User.hash_email(email)
          save(false)
        rescue Exception => e
          logger.error "Warning: register_user_to_fb for userid #{id}: #{e.message}"
        end
      end
    end
    def facebook_user?
      return !fb_user_id.nil? && fb_user_id > 0
    end
  else                          # no Facebook integration
    def self.create_from_fb_connect(fb_user) ; true ; end
    def link_fb_connect(fb_user_id) ; true ; end
    def register_user_to_fb ; true ; end
    def facebook_user? ; nil ; end
  end

  # merge myself with another customer.  'params' array indicates which
  # record (self or other) to retain each field value from.  For
  # password and salt, the ones corresponding to most recent
  # last_login are retained.  If those are equal, keep whichever was
  # most recently updated (updated_at).  IF those are also equal, keep
  # the first one.

  # merge with Anonymous customer, keeping all transactions

  def forget!
    return nil unless deletable?
    begin
      transaction do
        Customer.update_foreign_keys_from_to(self.id, Customer.anonymous_customer.id)
        self.destroy
      end
    rescue Exception => e
      self.errors.add_to_base "Cannot forget customer #{id} (#{full_name}): #{e.message}"
    end
    return self.errors.empty?
  end

  # expunge and rewrite history.  ALL other relations connected to this
  # customer are blown away with prejudice.

  def expunge!
    return nil unless deletable?
    begin
      transaction do
        Customer.delete_with_foreign_key(self.id)
        self.destroy
      end
    rescue Exception => e
      self.errors.add_to_base "Cannot expunge customer #{id} (#{full_name}): #{e.message}"
    end
  end

      
  def merge_with_params!(c1,params)
    return nil unless self.mergeable_with?(c1)
    Customer.replaceable_attributes.each do |attr|
      if (params[attr.to_sym].to_i > 0)
        self.send("#{attr}=", c1.send(attr))
      end
    end
    finish_merge(c1)
    return Customer.save_and_update_foreign_keys!(self, c1)
  end
  
  def merge_automatically!(c1)
    return nil unless self.mergeable_with?(c1)
    replace = c1.fresher_than?(self) && !c1.created_by_admin?
    Customer.replaceable_attributes.each do |attr|
      self.send("#{attr}=", c1.send(attr)) if replace || self.send(attr).blank?
    end
    finish_merge(c1)
    return Customer.save_and_update_foreign_keys!(self, c1)
  end
        
  def mergeable_with?(other)
    if other.special_customer?
      self.errors.add_to_base "Special customers cannot be merged away"
    elsif (self.special_customer? && self != Customer.anonymous_customer)
      self.errors.add_to_base "Merges disallowed into all special customers except Anonymous customer"
    end
    self.errors.empty?
  end
  

  def fresher_than?(other)
    begin
      (self.updated_at > other.updated_at) ||
        (self.updated_at == other.updated_at &&
        self.last_login > other.last_login)
    rescue
      nil
    end
  end

  private

  def finish_merge(c1)
    %w(comments tags role blacklist e_blacklist created_by_admin oldid fb_user_id email_hash).each do |attr|
      newval = merge_attribute(c1, attr)
      self.send("#{attr}=", newval)
    end
  end

  def merge_attribute(other, attr)
    v1 = self.send(attr)
    v2 = other.send(attr)
    newval =
      case attr.to_sym
      when :comments then [v1,v2].reject { |c| c.blank? }.join('; ')
      when :tags then (v1.to_s.downcase.split(/\s+/)+v2.to_s.downcase.split(/\s+/)).uniq.join(' ')
      when :role then [v1.to_i, v2.to_i].max  
      when :blacklist, :e_blacklist  then v1 || v2
      when :oldid, :fb_user_id, :email_hash
        if self.fresher_than?(other)
          v1.blank? ? v2 : v1
        else
          v2.blank? ? v1 : v2
        end
      when :created_by_admin, :inactive then v1 && v2
      else raise "No automatic merge procedure for #{attr.to_s.humanize}"
      end
  end

  # Note: This method should only be called inside a transaction block!
  def self.update_foreign_keys_from_to(old,new)
    msg = []
    Customer.update_all("referred_by_id = '#{new}'", "referred_by_id = '#{old}'")
    l = Label.rename_customer(old, new)
    msg << "#{l} labels"
    [Donation, Voucher, Txn, Visit, Import].each do |t|
      howmany = 0
      t.foreign_keys_to_customer.each do |field|
        howmany += t.update_all("#{field} = '#{new}'", "#{field} = '#{old}'")
      end
      msg << "#{howmany} #{t}s"
    end
    msg
  end

  def self.delete_with_foreign_key(old)
    # Getting ready to expunge a customer.
    # Donations, vouchers, visits and txns related to this customer are DELETED.
    [Donation,Voucher,Visit,Txn].each do |t|
      t.delete_all "customer_id = #{old}"
    end
    # Imports done by this customer are now done by Anonymous.
    anon_id = Customer.anonymous_customer.id
    Import.update_all("customer_id = #{anon_id}", "customer_id = #{old}")
    # Customers referred by this customer are now referred by Anonymous.
    Customer.update_all("referred_by_id = '#{new}'", "referred_by_id = '#{old}'")
  end
  
  def self.save_and_update_foreign_keys!(c0,c1)
    new = c0.id
    old = c1.id
    ok = nil
    msg = []
    begin
      transaction do
        msg = Customer.update_foreign_keys_from_to(old, new)
        # Crypted_password and salt have to be updated separately,
        # since crypted_password is automatically set by the before-save
        # action to be encrypted with salt.
        if c1.fresher_than?(c0)
          pass = c1.crypted_password
          salt = c1.salt
        else
          pass = nil
        end
        c1.destroy
        # Corner case. If a third record contains a duplicate email of either
        # of these, the merge will fail, and there will be nothing that can be
        # done about it!  So, temporarily set the created_by_admin bit on
        # the record to be preserved (which bypasses email uniqueness check)
        # and then reset afterward.
        old_created_by_admin = c0.created_by_admin
        c0.created_by_admin = true
        c0.save!
        c0.update_attribute(:created_by_admin, false) if !old_created_by_admin
        if pass
          Customer.connection.execute("UPDATE customers SET crypted_password='#{pass}',salt='#{salt}' WHERE id=#{c0.id}")
        end
        ok = "Transferred " + msg.join(", ") + " to customer id #{new}"
      end
    rescue Exception => e
      c0.errors.add_to_base "Customers NOT merged: #{e.message}"
    end
    return ok
  end

  # support for find_unique

  def self.match_email_and_last_name(email,last_name)
    !email.blank? && !last_name.blank? &&
      Customer.find(:first,:conditions => ['email LIKE ? AND last_name LIKE ?',
        email.strip, last_name.strip])
  end

  def self.match_first_last_and_address(first_name,last_name,street)
    !first_name.blank? && !last_name.blank? && !street.blank? &&
      Customer.find(:first,
      :conditions => ['first_name LIKE ? AND last_name LIKE ? AND street like ?',
        first_name, last_name, street])
  end

  def self.match_uniquely_on_names_only(first_name, last_name)
    return nil if first_name.blank? || last_name.blank?
    m = Customer.find(:all, 
      :conditions => ['last_name LIKE ? AND first_name LIKE ?',
        last_name, first_name])
    m && m.length == 1 ?  m.first : nil
  end
end


