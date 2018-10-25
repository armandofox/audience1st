class Customer < ActiveRecord::Base

  class CannotDestroySpecialCustomersError < RuntimeError ;  end

  ROLES = {
    :walkup => -1,
    :boxoffice_daemon => -2,
    :anonymous => -3,
    :generic => -4
  }

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
    raise CannotDestroySpecialCustomersError.new("Cannot destroy special customer entries") if self.special_customer?
  end

  def special_customer?
    self.role < 0  ||
      [Customer.nobody_id,
      Customer.walkup_customer.id,
      Customer.generic_customer.id].include?(self.id)
  end
  
  private

  def deletable? ; !self.special_customer? ; end

  def self.special_customer(which)
    Customer.find_by_role!(ROLES[which.to_sym])
  end

end
