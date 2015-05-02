module SessionsHelper

  def really_logged_in(customer)
    customer.kind_of?(Customer) && customer != Customer.anonymous_customer
  end

end
