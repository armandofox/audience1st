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

  class MissingDataError < StandardError ;  end

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
  # +description+: summary of what will be imported/added
  attr_accessor :description

  DO_NOT_IMPORT =         0
  ALREADY_IMPORTED =      -1
  CREATE_NEW_CUSTOMER =   -2
  USE_EXISTING_CUSTOMER = -3
  
  def initialize                # :nodoc:
    @order = Order.new(
      :processed_by => Customer.boxoffice_daemon,
      :purchasemethod => Purchasemethod.get_type_by_name('ext'))
    @customers = []
    @action = DO_NOT_IMPORT
    @comment = nil
  end

  def find_or_set_external_key(key)
    if Order.find_by(:external_key => key) # this order has already been imported
      self.action = ALREADY_IMPORTED
    else
      self.order.external_key = key
    end
  end

  def set_possible_customers(first,last,email=nil)
    if (!email.blank?  && (c = Customer.find_by_email(email)))
      # unique match
      self.customers = [c]
      self.action = USE_EXISTING_CUSTOMER
    else
      self.customers = Customer.possible_matches(first,last,email)
    end
  end

  def find_valid_voucher_for(thedate,vendor,price)
    showdate = Showdate.where(:thedate => thedate).first
    raise MissingDataError.new(I18n.translate('import.showdate_not_found', :date => thedate.to_formatted_s(:showtime_including_year))) if showdate.nil?
    vouchertype = Vouchertype.where("name LIKE ?", "%#{vendor}%").find_by(:season => showdate.season, :price => price)
    raise MissingDataError.new(I18n.translate('import.vouchertype_not_found',
        :season => ApplicationController.helpers.humanize_season(showdate.season),
        :vendor => import.vendor, :price => sprintf('%.02f', price_per_seat))) if vouchertype.nil?
    redemption = ValidVoucher.find_by(:vouchertype => vouchertype, :showdate => showdate)
    raise MissingDataError.new(I18n.translate('import.redemption_not_found',
        :vouchertype => vouchertype.name,:performance => showdate.printable_name)) if redemption.nil?
    redemption
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
    customer_args = { :first_name => @import_first_name, :last_name => @import_last_name }
    customer_args[:email] = @import_email unless @import_email.blank?
  end

end
