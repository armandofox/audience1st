class Order < ActiveRecord::Base
  acts_as_reportable
  
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :purchasemethod
  has_many :items, :dependent => :destroy
  has_many :vouchers, :dependent => :destroy

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
      errors.add_to_base "Walkup order requires purchaser & recipient to be walkup customer" unless
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

  def self.create_from_existing_items!(list_of_items)
    p = list_of_items.first
    max_string_length = Order.columns_hash['comments'].limit
    purchaser_id = p.gift_purchaser_id
    if (purchaser_id == 2146730911 ||  purchaser_id == 0 || purchaser_id == p.customer_id)
      # not really a gift order
      purchaser = p.customer
    else
      purchaser = p.gift_purchaser
    end
    params = {
      :walkup => p.walkup,
      :customer => p.customer,
      :purchaser => purchaser,
      :ship_to_purchaser => p.ship_to_purchaser,
      :sold_on => p.sold_on,
      :purchasemethod => p.purchasemethod,
      :comments => (list_of_items.map(&:comments).uniq.join('; '))[0, max_string_length],
      :items => list_of_items,
      :processed_by => p.processed_by || Customer.boxoffice_daemon
    }
    Order.create! params
  end

  def self.new_from_valid_voucher(valid_voucher, howmany, other_args)
    other_args[:purchasemethod] ||= Purchasemethod.find_by_shortdesc('none')
    order = Order.new(other_args)
    order.add_tickets(valid_voucher, howmany)
    order
  end

  def self.new_from_donation(amount, account_code, donor)
    order = Order.new(:purchaser => donor, :customer => donor)
    order.add_donation(Donation.from_amount_and_account_code_id(amount, account_code.id))
    order
  end

  def add_comment(arg)
    self.comments ||= ''
    self.comments += arg
  end

  def empty_cart!
    self.valid_vouchers = {}
    self.donation_data = {}
  end

  def cart_empty?
    valid_vouchers.empty? && donation.nil?
  end

  def add_with_checking(valid_voucher, number, promo_code)
    adjusted = valid_voucher.adjust_for_customer(promo_code)
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
  
  def has_mailable_items?
    # do any of the items require fulfillment?
    if completed?
      vouchers.any? { |v| v.vouchertype.fulfillment_needed? }
    else
      ValidVoucher.find(valid_vouchers.keys).any? { |vv| vv.vouchertype.fulfillment_needed? }
    end
  end

  def include_vouchers?
    if completed?
      items.any? { |v| v.kind_of?(Voucher) }
    else
      ticket_count > 0
    end
  end

  def include_regular_vouchers?
    if completed?
      items.any? { |v| v.kind_of?(Voucher) && !v.bundle? }
    else
      ValidVoucher.find(valid_vouchers.keys).any? { |vv| vv.vouchertype.category == :revenue }
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
    (items.map(&:one_line_description) << self.comments).join("\n")
  end

  def each_voucher
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
    errors.add_to_base "You must specify the enrollee's name for classes" if
      contains_enrollment? && comments.blank?
    check_purchaser_info unless processed_by.try(:is_boxoffice)
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

  def finalize!(sold_on_date = Time.now)
    raise Order::NotReadyError unless ready_for_purchase?
    begin
      transaction do
        vouchers = []
        valid_vouchers.each_pair do |valid_voucher_id, quantity|
          vv = ValidVoucher.find(valid_voucher_id)
          vv.customer = processed_by
          vouchers += vv.instantiate(quantity)
        end
        vouchers.flatten!
        # add non-donation items to recipient's account
        # if walkup order, mark the vouchers as walkup
        vouchers.each do |v|
          v.walkup = self.walkup?
        end
        customer.add_items(vouchers)
        unless customer.save
          raise Order::SaveRecipientError.new("Cannot save info for #{customer.full_name}: " + customer.errors.full_messages.join(', '))
        end
        # add donation items to purchaser's account
        purchaser.add_items([donation]) if donation
        unless purchaser.save
          raise Order::SavePurchaserError.new("Cannot save info for purchaser #{purchaser.full_name}: " + purchaser.errors.full_messages.join(', '))
        end
        self.sold_on = sold_on_date
        self.items += vouchers
        self.items += [ donation ] if donation
        self.items.each do |i|
          %w(processed_by comments).each do |attr|
            i.send("#{attr}=", self.send(attr))
          end
          i.gift_purchaser_id = purchaser.id if self.gift?
        end
        self.save!
        if purchasemethod.purchase_medium == :credit_card
          Store.pay_with_credit_card(self) or raise(Order::PaymentFailedError, self.errors.full_messages.join(', '))
        end
        # Log the order
        Txn.add_audit_record(:txn_type => 'oth_purch',
          :customer_id => purchaser.id,
          :logged_in_id => processed_by.id,
          :dollar_amount => total_price,
          :purchasemethod_id => purchasemethod.id,
          :order_id => self.id)
      end
    rescue ValidVoucher::InvalidRedemptionError => e
      raise Order::NotReadyError, e.message
    rescue Exception => e
      workaround_rails_bug_2298!
      raise e                 # re-raise exception
    end
  end

  def refundable_to_credit_card?
    completed? && purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

  def total
    # :BUG: 79120088: this should be replaceable by 
    #    items.sum(:amount)
    # when every Item's 'amount' field is correctly filled in at order time
    items.map(&:amount).sum
  end
  
  def purchasemethod_description
    purchasemethod.description
  end

  def item_descriptions
    items.map(&:item_description).
      inject(Hash.new(0)) { |h,v| h[v]+=1 ; h }.
      map { |item,count| ("%3d @ #{item}" % count) }.
      join("\n")
  end

end
