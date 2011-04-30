class Customer < ActiveRecord::Base

  public

  # The "customer" to whom all walkup tickets are sold
  
  def self.walkup_customer ; special_customer(:walkup) ; end
  def is_walkup_customer? ;  self.role == -1 && self.first_name =~ /^walkup$/i;   end

  # The box office daemon that handles background imports, etc.

  def self.boxoffice_daemon ; special_customer(:boxoffice_daemon) ; end

  # The anonymous customer (for deleting customers while preserving
  # their transactions)

  def self.anonymous_customer ; special_customer(:anonymous) ; end

  def cannot_destroy_special_customers
    raise "Cannot destroy special customer entries" if self.special_customer?
  end

  def special_customer?
    self.role < 0  ||
      [Customer.nobody_id,
      Customer.walkup_customer.id,
      Customer.generic_customer.id].include?(self.id)
  end
  
  def real_customer? ; !special_customer? ; end

  def self.all_customers ; Customer.find(:all, :conditions => 'role >= 0') ; end
  
  private

  def deletable? ; !self.special_customer? ; end


  #  Special customers that must exist, cannot be deleted, and are created
  # on demand if they don't exist:

  @@special_customers = {
    :walkup => {
      :role => -1, 
      :first_name => 'WALKUP',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true
    },
    :generic => {
      :role => -4,
      :first_name => 'GENERIC',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true,
    },
    :boxoffice_daemon => {
      :role => -2,
      :first_name => 'BoxOffice',
      :last_name => 'Daemon',
      :blacklist => true,
      :e_blacklist => true
    },
    :anonymous => {
      :role => -3,
      :first_name => 'ANONYMOUS',
      :last_name => 'CUSTOMER',
      :blacklist => true,
      :e_blacklist => true
    }
  }

  # helper method used to create 'special' customers and immediately set
  # the Role attribute (since that attribute is protected and can't be
  # set directly in the create call)

  def self.create_with_role!(which)
    attrs = @@special_customers[which]
    c = Customer.new(attrs)
    c.role = attrs[:role]
    c.created_by_admin = true
    c.save!
    c
  end

  def self.special_customer(which)
    Customer.find_by_role(@@special_customers[which][:role]) ||
      Customer.create_with_role!(which)
  end

end
