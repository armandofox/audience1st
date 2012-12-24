class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :purchasemethod
  has_many :items

  validates_presence_of :sold_on
  validates_presence_of :processed_by_id
  validates_presence_of :purchasemethod_id
  validates_presence_of :customer_id
  validates_presence_of :purchaser_id

  attr_reader :cart_items

  class Order::NotReadyError < StandardError ; end
  class Order::SaveRecipientError < StandardError; end
  
  def initialize(*args)
    @cart_items = []
    super
  end

  def workaround_rails_bug_2298!
    # Rails Bug 2298: when a db txn fails, the id's of the instantiated objects
    # that were not saved are NOT reset to nil, which causes problems when they are
    # successfully saved later on (eg when transaction is rerun).  Also, new_record is
    # not correctly reset to true.
    # the fix is based on a patch shown here:
    # http://s3.amazonaws.com/activereload-lighthouse/assets/fe67deaf98bb15d58218acdbbdf7d4f166255ad3/after_transaction.diff?AWSAccessKeyId=1AJ9W2TX1B2Z7C2KYB82&Expires=1263784877&Signature=ZxQebT1e9lG8hqexXb6IMvlfw4Q%3D
    self.items.each do |i|
      i.instance_eval {
        @attributes.delete(self.class.primary_key)
        @attributes_cache.delete(self.class.primary_key)
        @new_record = true
      }
    end
  end


  def empty_cart! ;     @cart_items = [] ;    end
  def cart_empty? ;     @cart_items.empty? ;  end   
  def add_item(item) ;  @cart_items << item ; end

  def include_vouchers? ; @cart_items.any? { |v| v.kind_of? Voucher } ; end
  def include_donation? ; @cart_items.any? { |v| v.kind_of? Donation } ; end
  def cart_vouchers ;     @cart_items.select { |i| i.kind_of? Voucher } ; end
  def cart_donations ;    @cart_items.select { |i| i.kind_of? Donation } ; end

  def gift?
    ready_for_purchase? &&  include_vouchers?  &&  customer != purchaser
  end

  def extract_showdates
    cart_vouchers.map { |v| v.showdate.try(:printable_date) }.uniq.compact
  end

  def total_price ;     @cart_items.sum(&:amount) ; end

  def summary
    item_list = purchased? ? items : @cart_items
    (item_list.map(&:one_line_description) + all_comments).join("\n")
  end

  def purchased? ;    !sold_on.blank? ; end


  def add_comment(comment)
    cart_vouchers.each { |v| v.add_comment comment }
  end


  def ready_for_purchase?
    errors.clear
    errors.add_to_base 'Shopping cart is empty' if @cart_items.empty?
    errors.add_to_base 'No purchaser information' unless purchaser.kind_of?(Customer)
    errors.add_to_base "Purchaser information is incomplete: #{purchaser.errors.full_messages.join(', ')}" if purchaser.kind_of?(Customer) && !purchaser.valid_as_purchaser?
    errors.add_to_base 'No recipient information' unless customer.kind_of?(Customer)
    errors.add(:customer, customer.errors.full_messages.join(',')) if customer.kind_of?(Customer) && !customer.valid_as_gift_recipient?
    errors.add(:purchasemethod, 'No payment method specified') unless purchasemethod.kind_of?(Purchasemethod)
    errors.add_to_base 'No information on who processed order' unless processed_by.kind_of?(Customer)
    errors.empty?
  end

  def finalize!
    raise Order::NotReadyError unless ready_for_purchase?
    self.sold_on = Time.now
    self.items += cart_items
    self.items.each { |i| i.update_attribute(:purchasemethod, purchasemethod) }
    self.save!
    # add non-donation items to recipient's account
    customer.add_items(cart_vouchers, processed_by.id, purchasemethod)
    raise Order::SaveRecipientError.new(customer.errors.full_messages.join(', ')) unless customer.save
    # add donation items to purchaser's account
    purchaser.add_items(cart_donations, processed_by.id, purchasemethod)
    raise Order::SavePurchaserError.new(purchaser.errors.full_messages.join(', ')) unless purchaser.save
  end

  def refundable_to_credit_card?
    purchased? && purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

  protected

  def all_comments
    (purchased? ? items : @cart_items).map(&:comments).uniq
  end

end
