class Customer < ActiveRecord::Base

  class CannotDestroySpecialCustomersError < RuntimeError ;  end

  public

  # The "customer" to whom all walkup tickets are sold
  
  def self.walkup_customer
    Customer.find_by!(:role => -1)
  end
  
  def is_walkup_customer? ;  self.role == -1 && self.first_name =~ /^walkup$/i;   end

  # The box office daemon that handles background imports, etc.

  def self.boxoffice_daemon
    Customer.find_by!(:role => -2)
  end

  # The anonymous customer (for deleting customers while preserving
  # their transactions)

  def self.anonymous_customer
    Customer.find_by!(:role => -3)
  end

  def cannot_destroy_special_customers
    raise CannotDestroySpecialCustomersError.new("Cannot destroy special customer entries") if self.special_customer?
  end

  def special_customer?
    self.role < 0
  end
  
  private

  def deletable? ; !self.special_customer? ; end

end
