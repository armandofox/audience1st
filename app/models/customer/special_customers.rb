module Customer::SpecialCustomers
  extend ActiveSupport::Concern

  class CannotDestroySpecialCustomersError < RuntimeError ;  end

  class_methods do

    # The "customer" to whom all walkup tickets are sold
    
    def walkup_customer
      Customer.find_by!(:role => -1)
    end
    

    # The box office daemon that handles background imports, etc.

    def boxoffice_daemon
      Customer.find_by!(:role => -2)
    end

    # The anonymous customer (for deleting customers while preserving
    # their transactions)

    def anonymous_customer
      Customer.find_by!(:role => -3)
    end
  end
  def is_walkup_customer? ;  self.role == -1 && self.first_name =~ /^walkup$/i;   end

  def cannot_destroy_special_customers
    raise CannotDestroySpecialCustomersError.new("Cannot destroy special customer entries") if self.special_customer?
  end

  def special_customer?
    self.role < 0
  end
  
  private

  def deletable? ; !self.special_customer? ; end

end
