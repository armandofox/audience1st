class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :purchasemethod
  has_many :items

  validates_presence_of :processed_by_id

  attr_accessor :purchase_args

  class Order::NotReadyError < StandardError ; end
  class Order::SaveRecipientError < StandardError; end
  class Order::PaymentFailedError < StandardError; end
  
  def initialize(*args)
    @purchase_args = {}
    super
  end
  def after_initialize ; self.valid_vouchers = {} ; end
  
  serialize :valid_vouchers, Hash
  serialize :donation

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


  def empty_cart!
    self.valid_vouchers = {}
    self.donation = nil
  end

  def cart_empty?
    valid_vouchers.empty? && donation.nil?
  end

  def add_tickets(valid_voucher, number)
    key = valid_voucher.id
    valid_vouchers[key] ||= 0
    valid_vouchers[key] += number
  end

  def add_donation(d)
    self.donation = d
  end
    
  def ticket_count ; valid_vouchers.values.map(&:to_i).sum ; end

  def include_vouchers? ; ticket_count > 0 ; end
  def include_donation? ; !donation.nil?   ; end

  def gift?
    ready_for_purchase? &&  include_vouchers?  &&  customer != purchaser
  end

  def total_price
    total = donation.try(:amount).to_f
    valid_vouchers.each_pair do |vv_id, qty| 
      total += ValidVoucher.find(vv_id).price * qty
    end
    total
  end
  
  def summary
    item_list = completed? ? items : cart_items
    (item_list.map(&:one_line_description) + all_comments).join("\n")
  end

  def completed? ;  !new_record?  &&  !sold_on.blank? ; end

  def ready_for_purchase?
    errors.clear
    errors.add_to_base 'Shopping cart is empty' if cart_empty?
    errors.add_to_base 'No purchaser information' unless purchaser.kind_of?(Customer)
    errors.add_to_base "Purchaser information is incomplete: #{purchaser.errors.full_messages.join(', ')}" if purchaser.kind_of?(Customer) && !purchaser.valid_as_purchaser?
    errors.add_to_base 'No recipient information' unless customer.kind_of?(Customer)
    errors.add(:customer, customer.errors.full_messages.join(',')) if customer.kind_of?(Customer) && !customer.valid_as_gift_recipient?
    if purchasemethod.kind_of?(Purchasemethod)
      errors.add(:purchasemethod, 'Invalid credit card transaction') if
        purchase_args[:credit_card_token].blank?       &&
        purchasemethod.purchase_medium == :credit_card 
      errors.add(:purchasemethod, 'Zero amount') if
        total_price.zero? && purchasemethod.purchase_medium != :cash
    else
      errors.add(:purchasemethod, 'No payment method specified')
    end
    errors.add_to_base 'No information on who processed order' unless processed_by.kind_of?(Customer)
    errors.empty?
  end

  def finalize!
    raise Order::NotReadyError unless ready_for_purchase?
    vouchers = valid_vouchers.keys.map do |valid_voucher_id|
      ValidVoucher.find(valid_voucher_id).instantiate(processed_by, purchasemethod, valid_vouchers[valid_voucher_id])
      end.flatten
    transaction do
      # add non-donation items to recipient's account
      customer.add_items(vouchers, processed_by.id, purchasemethod)
      raise Order::SaveRecipientError.new(customer.errors.full_messages.join(', ')) unless customer.save
      # add donation items to purchaser's account
      purchaser.add_items([donation], processed_by.id, purchasemethod) if donation
      raise Order::SavePurchaserError.new(purchaser.errors.full_messages.join(', ')) unless purchaser.save
      self.sold_on = Time.now
      self.items += vouchers
      self.items += [ donation ] if donation
      self.items.each do |i|
        i.purchasemethod = purchasemethod
        i.sold_on = sold_on
        i.gift_purchaser_id = purchaser.id if self.gift?
      end
      self.save!
      if purchasemethod.purchase_medium == :credit_card
        unless Store.pay_with_credit_card(self)
          self.reload unless new_record?
          workaround_rails_bug_2298!
          raise Order::PaymentFailedError
        end
      end
    end
  end

  def refundable_to_credit_card?
    completed? && purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

  protected

  def all_comments
    (completed? ? items : cart_items).map(&:comments).uniq
  end

end
