require 'digest/sha1'

class Customer < ActiveRecord::Base

  has_many :vouchers, :dependent => :destroy
  has_many :showdates, :through => :vouchers
  has_many :shows, :through => :showdates
  has_many :txns
  has_one  :most_recent_txn, :class_name=>'Txn', :order=>'txn_date DESC'
  has_many :donations
  has_many :visits
  has_one :most_recent_visit, :class_name => 'Visit', :order=>'thedate DESC'
  has_one :next_followup, :class_name => 'Visit', :order => 'followup_date'
  
  validates_uniqueness_of :login, :allow_nil => true
  validates_length_of :login, :in => 3..50, :allow_nil => true
  
  validates_presence_of :first_name
  validates_length_of :first_name, :within => 1..50
  validates_presence_of :last_name
  validates_length_of :last_name, :within => 1..50

  #validates_length_of :password, :in => 3..20, :allow_nil => true
  #validates_confirmation_of :password

  validates_columns :formal_relationship
  validates_columns :member_type

  attr_protected :id, :salt, :role, :vouchers, :donations, :validation_level
  attr_accessor :password

  # before validation, squeeze out any attributes that are whitespace-only,
  # so the allow_nil validations behave as expected.

  before_validation :remove_blank_attributes
  def remove_blank_attributes
    Customer.columns.each do |c|
      self.send("#{c.name}=", nil) if self.send(c.name).blank?
    end
    self.password = nil if self.password.blank?
  end

  # custom validations

  def valid_as_gift_recipient?
    # must have first and last name, and two out of three of
    #  address, email and phone#
    valid = true
    if (first_name.blank? || last_name.blank?)
      errors.add_to_base "First and last name must be provided"
      valid = false
    end
    if invalid_mailing_address?
      errors.add_to_base "Valid mailing address must be provided"
      valid = false
    end
    if day_phone.blank? && eve_phone.blank? && !has_valid_email_address?
      errors.add_to_base "At least one phone number or email address must be provided"
      valid = false
    end
    valid
  end
  
  @@user_entered_strings =
    %w[first_name last_name street city state zip day_phone eve_phone login]
  
  # strip whitespace before saving
  def before_save
    @@user_entered_strings.each do |col|
      c = self.send(col)
      c.send(:strip!) if c.kind_of?(String)
    end
  end

  def self.extra_attributes
    [:referred_by_id, :referred_by_other, :formal_relationship, :member_type,
     :company, :title, :company_address_line_1, :company_address_line_2,
     :company_city, :company_state, :company_zip, :work_phone, :cell_phone,
     :work_fax, :company_url]
  end

  def display_class
    self.is_staff ? :staff :
      self.is_subscriber? ? :subscriber : nil
  end
  
  # a convenient wrapper class for the ActiveRecord::sanitize_sql protected method

  def self.render_sql(sql)
    ActiveRecord::Base.sanitize_sql(sql)
  end
  
  def full_name
    "#{self.first_name.name_capitalize} #{self.last_name.name_capitalize}"
  end

  def sortable_name
    "#{self.last_name.downcase},#{self.first_name.downcase}"
  end

  def has_valid_email_address?
    self.login && self.login.valid_email_address?
  end
  
  def is_subscriber?
    self.role >= 0 &&
      self.vouchers.detect do |f|
      f.vouchertype && f.vouchertype.is_subscription? &&
        f.vouchertype.valid_now?
    end
  end

  def referred_by_name(maxlen=1000)
    if (c = Customer.find_by_id(self.referred_by_id.to_i))
      c.full_name[0..maxlen-1]
    else
      self.referred_by_other.to_s[0..maxlen-1]
    end
  end

  # XXX: BUG this should be implemented using has_many with :conditions,
  # but not sure how since expiration-date and valid-date are columns of
  # vouchertype, not of voucher....
  def active_vouchers
    t = Time.now
    self.vouchers.select { |v| (v.valid_date <= t  &&  v.expiration_date >= t) }
  end
  
  # merge myself with another customer.  'params' array indicates which
  # record (self or other) to retain each field value from.  For
  # password and salt, the ones corresponding to most recent
  # last_login are retained.  If those are equal, keep whichever was
  # most recently updated (updated_at).  IF those are also equal, keep
  # the first one.

  def merge_with(c1,params)
    c0 = self
    c = [c0,c1]
    Customer.content_columns.each do |col|
      if (params[col.name.to_sym].to_i > 0)
        c0.send(col.name+"=", c1.send(col.name))
      end
    end
    # role column keeps the more privileged of the two roles
    c0.role = c1.role if c1.role > c0.role
    # validation_level keeps the higher of the two validation levels
    c0.validation_level = c1.validation_level if c1.validation_level > c0.validation_level
    # passwd,salt columns are kept based on last_login or updated_at
    if (((c0.last_login < c1.last_login) ||
        ((c0.last_login == c1.last_login) && (c0.updated_on <
                                              c1.updated_on))) rescue nil)
      c0.hashed_password = c1.hashed_password
      c0.salt = c1.salt
    end                         # else keep what we have
    msg = []
    # oldid: if only one nonzero, keep that one.  otherwise keep
    # higher-numbered one, and report this fact.
    c0.oldid = c1.oldid if c0.oldid.zero?
    new = c0.id
    old = c1.id
    begin
      # special case: since login must be unique, if the two logins are
      # non-nil and equal a validation error will prevent the save. to
      # avoid this, temporarily nil out the one that WON'T be saved.
      # if the save fails, its value is restored in the rescue clause.
      if (c0.login && c1.login && c0.login==c1.login)
        temp = c1.login
        c1.login = nil          # this is allowed by validation rules
        c1.save!
      end
      c0.save!
      [Donation, Voucher, Txn].each do |t|
        howmany = t.update_all("customer_id = '#{new}'", "customer_id = '#{old}'")
        msg << "#{howmany} #{t}s"
      end
      # also handle the processed_by field for vouchers & donations & the entered_by
      # field for Txns, both of which are really a customer id
      Voucher.update_all("processed_by = '#{new}'", "processed_by = '#{old}'")
      Donation.update_all("processed_by = '#{new}'", "processed_by = '#{old}'")
      Txn.update_all("entered_by_id = '#{new}'", "entered_by_id = '#{old}'")
      c[1].destroy
      status = "Transferred " + msg.join(",") + " to customer id #{new}"
      ok = true
    rescue Exception => e
      if defined?(temp) && temp
        c1.update_attribute(:login, temp)
      end
      ok = false
      status = "Customers NOT merged: #{e.message}"
    end
    return [ok,status]
  end



  # add items to a customer's account - could be vouchers, record of a
  # donation, or purchased goods

  def add_items(items, logged_in, howpurchased=Purchasemethod.get_type_by_name('web_cc'), comment='')
    items.each do |v|
      if v.kind_of?(Voucher)
        v.processed_by = logged_in
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
                               :purchasemethod_id => howpurchased)
        else
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
        raise "Can't add this product type to customer record"
      end
    end
  end    

  def password=(pass)
    @password=pass.to_s.strip
    self.salt = String.random_string(10)
    self.hashed_password = Customer.encrypt(@password, self.salt)
  end

  def self.encrypt(pass,salt)
    Digest::SHA1.hexdigest(pass.strip.to_s+salt.to_s)
  end

  # Authenticate: if password matches login, return customer id, else
  # a symbol explaining what failed

  def self.authenticate(login,pass)
    u=Customer.find(:first, :conditions=>["login LIKE ?", login])
    return :login_not_found unless u.kind_of?(Customer)
    if Customer.encrypt(pass,u.salt) == u.hashed_password
      return u
    else
      return :bad_password
    end
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
  
  # you can grant someone else a particular role as long as it's less
  # than your own. 

  def can_grant(newrole)
    # TBD should really check that the two are
    # in different role-equivalence classes 
    self.role > Customer.role_value(newrole)
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

  # a dummy customer that is cannot be deleted from the database
  def self.walkup_customer;  Customer.find_by_role(-1);   end

  def is_walkup_customer? ;  self.role == -1;   end

  def real_customer?
    ! [Customer.nobody_id, Customer.walkup_customer.id,
       Customer.generic_customer.id].include?(self.id)
  end

  # a generic customer who is a 'stand in' for determining customer
  # privileges; the least common denominator
  def self.generic_customer
    Customer.find_by_role(-1)
    # for now, same as the 'walkup customer'
  end
  
  def before_destroy
    raise "Cannot destroy walkup customer entry" if self.role == -1
  end

  @@roles.each do |r|
    role = r.first
    lvl = r.last
    eval "def is_#{role}; self.role >= #{lvl}; end"
  end

  # given some customer info, find this customer in the database with
  # high confidence; but if not found, create new record for this
  # customer and return that.

  def self.find_unique(p)
    p.symbolize_keys!
    c = nil
    # attempt 0: try exact match on email; first/last name must ALSO match
    if (!p[:login].blank?) &&
        (m = Customer.find(:first, :conditions => ['login LIKE ?', p[:login].strip])) &&
        # email matches - but unless name & address also match, we're screwed.
        m.first_name.casecmp(p[:first_name]).zero? &&
        m.last_name.casecmp(p[:last_name]).zero?
      return m
    end
    # either email didn't match, or email matched but names didn't.
    # so, attempt 1: try exact match on last name and first name
    if (!(p[:last_name].blank?) && !(p[:first_name].blank?) &&
        (matches = Customer.find(:all, :conditions => ['last_name LIKE ? AND first_name LIKE ?', p[:last_name], p[:first_name]])))
      if (matches.to_a.length == 1)  # exactly 1 match - victory
        c = matches.first
      elsif (!p[:login].blank? &&
             p[:login].valid_email_address? &&
             (m = matches.find_all { |cust| cust.login.casecmp(p[:login]).zero? }) &&
             m.length == 1)  # multiple names, but exact hit on email
        c = m.first
      end
    end
    c
  end

  def self.new_or_find(p, loggedin_id=0)
    unless (c = Customer.find_unique(p))
      c = Customer.new(p)
      # precaution: make sure login is unique.
      if c.login
        c.login = nil if Customer.find(:first,:conditions => ['login like ?',c.login])
      end
      c.save!
      Txn.add_audit_record(:txn_type => 'edit',
                           :customer_id => c.id,
                           :comments => 'customer not found, so created',
                           :logged_in_id => loggedin_id)
    end
    c
  end
      
                           
  # Override content_columns method to omit password hash and salt
  def self.content_columns
    super.delete_if { |x| x.name.match(%w[role oldid hashed_password salt _at$ _on$].join('|')) }
  end

  def self.address_columns
    self.content_columns.select {
      |x| x.name.match('first_name|last_name|street|city|state|zip') 
    }
  end

  # check if mailing address appears valid.
  # TBD: should use a SOAP service to do this when a cust record is saved, and flag entry if 
  #bad address. 

  def self.find_all_subscribers(order_by='last_name')
    Customer.find_by_sql("SELECT DISTINCT " <<
                         "c.first_name,c.last_name,c.street,c.city,c.state,c.zip " <<
                         " FROM customers c JOIN vouchers v ON v.customer_id=c.id " <<
                         " JOIN vouchertypes vt on v.vouchertype_id=vt.id " <<
                         " WHERE vt.is_subscription=1 AND " <<
                         "vt.valid_date <= NOW() AND vt.expiration_date >= NOW() " <<
                         " ORDER BY #{order_by}")
  end
  
  def invalid_mailing_address?
    return (self.street.blank? or self.city.blank? or self.state.blank? or self.zip.to_s.length < 5)
  end
  
end
