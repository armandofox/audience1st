class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :purchasemethod
  has_many :items
  has_many :vouchers

  validates_presence_of :processed_by_id

  attr_accessor :purchase_args

  delegate :purchase_medium, :to => :purchasemethod
  
  class Order::NotReadyError < StandardError ; end
  class Order::SaveRecipientError < StandardError; end
  class Order::SavePurchaserError < StandardError ; end
  class Order::PaymentFailedError < StandardError; end
  
  serialize :valid_vouchers, Hash
  serialize :donation_data, Hash

  def initialize(*args)
    @purchase_args = {}
    @walkup = false
    super
  end

  def after_initialize
    self.donation_data ||= {}
    unless donation_data.empty?
      @donation = Donation.new(:amount => donation_data[:amount], :account_code_id => donation_data[:account_code_id])
    end
    self.valid_vouchers ||= {}
  end

  private

  def check_purchaser_info
    # walkup orders only need purchaser & recipient info to point to walkup
    #  customer, but regular orders need full purchaser & recipient info.
    if walkup?
      errors.add_to_base "Walkup order requires purchaser & recipient to be walkup customer"unless
        (purchaser == Customer.walkup_customer && customer == purchaser)
    else
      errors.add_to_base "Purchaser information is incomplete: #{purchaser.errors.full_messages.join(', ')}" if
        purchaser.kind_of?(Customer) && !purchaser.valid_as_purchaser?
      errors.add_to_base 'No recipient information' unless customer.kind_of?(Customer)
      errors.add(:customer, customer.errors.full_messages.join(',')) if customer.kind_of?(Customer) && !customer.valid_as_gift_recipient?
    end
  end

  def workaround_rails_bug_2298!
    # Rails Bug 2298: when a db txn fails, the id's of the instantiated objects
    # that were not saved are NOT reset to nil, which causes problems when they are
    # successfully saved later on (eg when transaction is rerun).  Also, new_record is
    # not correctly reset to true.
    # the fix is based on a patch shown here:
    # http://s3.amazonaws.com/activereload-lighthouse/assets/fe67deaf98bb15d58218acdbbdf7d4f166255ad3/after_transaction.diff?AWSAccessKeyId=1AJ9W2TX1B2Z7C2KYB82&Expires=1263784877&Signature=ZxQebT1e9lG8hqexXb6IMvlfw4Q%3D
    # If any of the saves was on a record that had already been saved previously,
    #   we can just reload it instead; but we have to force trying this since we can't
    #   trust @new_record to tell us this fact.
    # If reload fails, and it really was a new record, we have to apply the fix.
    reset_primary_key_and_new_record_on(self)
    reset_primary_key_and_new_record_on(self.purchaser)
    reset_primary_key_and_new_record_on(self.customer)
    self.items.each { |i| reset_primary_key_and_new_record_on(i) }
  end

  def reset_primary_key_and_new_record_on(thing)
    begin
      thing.reload
    rescue ActiveRecord::RecordNotFound
      thing.instance_eval do
        @attributes.delete(self.class.primary_key)
        @attributes_cache.delete(self.class.primary_key)
        @new_record = true
      end
    end
  end
  
  public

  def empty_cart!
    self.valid_vouchers = {}
    self.donation_data = {}
  end

  def cart_empty?
    valid_vouchers.empty? && donation.nil?
  end

  def add_with_checking(valid_voucher, number, customer, promo_code)
    adjusted = valid_voucher.adjust_for_customer(customer, promo_code)
    if number <= adjusted.max_sales_for_type
      self.add_tickets(valid_voucher, number)
    else
      self.errors.add_to_base(adjusted.explanation)
    end
  end

  def add_tickets(valid_voucher, number)
    key = valid_voucher.id
    self.valid_vouchers[key] ||= 0
    self.valid_vouchers[key] += number
  end

  def add_donation(d) ; self.donation = d ; end
  def donation=(d)
    self.donation_data[:amount] = d.amount
    self.donation_data[:account_code_id] = d.account_code_id
    @donation = d
  end
  attr_reader :donation
  
  def ticket_count ; valid_vouchers.values.map(&:to_i).sum ; end

  def item_count ; ticket_count + (include_donation? ? 1 : 0) ; end
  
  def tickets_for_date(date)
    valid_vouchers.select { |v| v.thedate == date }
  end

  def tickets_of_type(vouchertype)
    valid_vouchers.select { |v| v.vouchertype == vouchertype }
  end
  
  def include_vouchers?
    if completed?
      items.any? { |v| v.kind_of?(Voucher) }
    else
      ticket_count > 0
    end
  end
  
  def include_donation?
    if completed?
      items.any? { |v| v.kind_of?(Donation) }
    else
      !donation.nil?
    end
  end

  def contains_enrollment?
    ValidVoucher.find(valid_vouchers.keys).any? { |v| v.event_type == 'Class' }
  end

  def gift?
    include_vouchers?  &&  customer != purchaser
  end

  def total_price
    return items.map(&:amount).sum if completed?
    total = self.donation.try(:amount).to_f
    valid_vouchers.each_pair do |vv_id, qty| 
      total += ValidVoucher.find(vv_id).price * qty
    end
    total
  end
  
  def summary
    item_list = completed? ? items : cart_items
    (item_list.map(&:one_line_description) + all_comments).join("\n")
  end

  def each_voucher_in_cart
    valid_vouchers.each_pair do |id,num|
      v = ValidVoucher.find(id)
      num.times { yield v }
    end
  end

  def completed? ;  !new_record?  &&  !sold_on.blank? ; end

  def ready_for_purchase?
    errors.clear
    errors.add_to_base 'Shopping cart is empty' if cart_empty?
    errors.add_to_base 'No purchaser information' unless purchaser.kind_of?(Customer)
    check_purchaser_info
    if purchasemethod.kind_of?(Purchasemethod)
      errors.add(:purchasemethod, 'Invalid credit card transaction') if
        purchase_args && purchase_args[:credit_card_token].blank?       &&
        purchase_medium == :credit_card 
      errors.add(:purchasemethod, 'Zero amount') if
        total_price.zero? && purchase_medium != :cash
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
    begin
      transaction do
        # add non-donation items to recipient's account
        # if walkup order, mark the vouchers as walkup
        vouchers.each { |v| v.walkup = self.walkup? }
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
          raise Order::PaymentFailedError unless Store.pay_with_credit_card(self)
        end
      end
    rescue Exception => e
      workaround_rails_bug_2298!
      raise e                 # re-raise exception
    end
  end

  def refundable_to_credit_card?
    completed? && purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

  def all_comments
    (completed? ? items : cart_items).map(&:comments).uniq
  end

end
