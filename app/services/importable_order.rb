# This class captures the abstraction of "an order that is almost ready to be imported,
# once we ascertain which customer should get it".  Each instance has an associated +Order+
# object whose +processed_by+ is set to the special customer "box office daemon", and whose
# payment method is set to "sold by external vendor".  Each instance has an associated
# list of +Customer+ objects (which may be empty) of the candidate Customers to which the
# order *could* be assigned based on name/email/etc. matching from an imported will-call list
# or sales list.
#
# Ultimately, the underlying +Order+'s +purchaser+ and +customer+ will both be
# set to the receiving customer (the caller will create a new customer if none are suggested),
# and the order's +external_key+ will be set to the vendor's order ID or order number.

class ImportableOrder

  attr_accessor :order
  attr_accessor :customers

  def initialize                # :notnew:
    @order = Order.new(
      :processed_by => Customer.boxoffice_daemon,
      :purchasemethod => Purchasemethod.get(:ext))
    @customers = []
  end

end
