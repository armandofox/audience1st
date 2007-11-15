require 'digest/sha1'

class String
  def self.random_string(len)
    # generate a random string of alphanumerics, but to avoid user confusion,
    # omit o/0 and 1/i/l
    newpass = ''
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a - %w[O o L l I i]
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def valid_email_address?
    return self && self.match( /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.([A-Z]{2,4})?$/i )
  end

end

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
  validates_length_of :login, :in => 3..30, :allow_nil => true
  
  validates_presence_of :first_name
  validates_length_of :first_name, :within => 1..30
  validates_presence_of :last_name
  validates_length_of :last_name, :within => 1..30

  validates_length_of :password, :in => 3..20, :allow_nil => true
  validates_confirmation_of :password

  validates_columns :formal_relationship
  validates_columns :member_type

  attr_protected :id, :salt, :role, :vouchers, :donations, :validation_level
  attr_accessor :password

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

  def is_2008_subscriber?
    self.role >= 0 &&
      self.vouchers.any? { |f| f.vouchertype.name.match /2008/ }
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
    c0.role = [c0.role,c1.role].max
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

  def add_items(items, logged_in, howpurchased=Purchasemethod.get_type_by_name('cust_web'), comment='')
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

  # Authenticate: if password matches login, set the current customer
  # id, and in addition, set is_admin flag if this customer is an admin.
  # If password doesn't match, return nil and ensure current customer is
  # unset.

  def self.authenticate(login,pass)
    u=find(:first, :conditions=>["login LIKE ?", login])
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

  def self.get_customer(id)
    Customer.find(id.to_i) rescue nil
  end

  @@roles.each do |r|
    role = r.first
    lvl = r.last
    eval "def is_#{role}; self.role >= #{lvl}; end"
  end

  # given some customer info, find this customer in the database with
  # high confidence; but if not found, create new record for this
  # customer and return that.

  def self.new_or_find(p, loggedin_id=0)
    params = p.symbolize_keys
    # attempt 1: try exact match on last name and first name
    if (!(params[:last_name].to_s.empty?) &&
        !(params[:first_name].to_s.empty?) &&
        (matches = Customer.find(:all, :conditions => ['last_name LIKE ? AND first_name LIKE ?', params[:last_name], params[:first_name]])) &&
        (matches.to_a.length == 1))  # exactly 1 match - victory
      c = matches.first
    else
      c = Customer.new(params)
      unless c.has_valid_email_address?
        c.login = String.random_string(8)
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
    c = super
    c.delete_if { |x| x.name.match(%w[role last_login hashed_password salt _at$ _on$].join('|')) }
    return c
  end

  def self.address_columns
    self.content_columns.select {
      |x| x.name.match('first_name|last_name|street|city|state|zip') 
    }
  end

  # check if mailing address appears valid.
  # TBD: should use a SOAP service to do this when a cust record is saved, and flag entry if 
  #bad address. 
  
  def invalid_mailing_address?
    return (self.validation_level < 1 or self.street.blank? or self.city.blank? or self.state.blank? or self.zip.to_s.length < 5)
  end
  
  def self.find_subs
    sub2007 = (21..26).to_a + (29..32).to_a
    sub2008 = (55..58).to_a

    c = Customer.find_by_sql("SELECT DISTINCT c.* FROM customers c,vouchers v WHERE c.id=v.customer_id AND ((v.vouchertype_id >= 21 AND v.vouchertype_id <= 26) OR (v.vouchertype_id >= 29 AND v.vouchertype_id <= 32))")

    puts "#{c.size} 2007 subscriber households"
    c.reject! { |cu| cu.vouchers.any? { |v| sub2008.include?(v.vouchertype_id) } }
    puts "#{c.size} who have NOT renewed 2008"
    out = File.open('/tmp/csvout','wb') 
    CSV::Writer.generate(out) do |csv|
      c.each do |cu|
        csv << [cu.first_name, cu.last_name, cu.street, cu.city, cu.state, cu.zip]
      end
    end
    out.close
  end
end
