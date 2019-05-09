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
  # +import_first_name,import_last_name+: first and last name as given in the import list
  attr_accessor :import_first_name, :import_last_name
  # +customer_email_in_import+: if given, the email address from import list
  attr_accessor :import_email
  # +customers+: a collection of candidate Customer records to import to
  attr_accessor :customers
  # +action+: index of selected action. 0=do not import, 1=create new customer,
  # 2..n-2=import to selected customer
  attr_accessor :action
  # +comment+: optional comment added by staff at import time that becomes the comment field
  # of the order

  DO_NOT_IMPORT = 0
  CREATE_NEW_CUSTOMER = 1

  def initialize                # :nodoc:
    @order = Order.new(
      :processed_by => Customer.boxoffice_daemon,
      :purchasemethod => Purchasemethod.get(:ext))
    @customers = []
    @action = DO_NOT_IMPORT
    @comment = nil
  end

  def finalize!
    # copy comment to order
    @order.comment = @comment
    case @action
    when DO_NOT_IMPORT
      return true
    when CREATE_NEW_CUSTOMER
      finalize_with_new_customer!
    else
      finalize_with_existing_customer!
    end
  end

  private

  def finalize_with_existing_customer!
    customer = @customers[@action - 2]
    @order.purchaser = customer
    @order.recipient = customer
    @order.finalize!
  end

  def finalize_with_new_customer!
    if 
    end
    customer_args = { :first_name => @import_first_name, :last_name => @import_last_name }
    customer_args[:email] = @import_email unless @import_email.blank?
  end

end
