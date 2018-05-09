class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :purchasemethod
  has_many :items, :dependent => :destroy
  has_many :vouchers, :dependent => :destroy
  has_many :donations, :dependent => :destroy
  has_many :retail_items, :dependent => :destroy

  attr_accessor :purchase_args
  attr_reader :donation

  attr_accessible :comments, :processed_by, :customer, :purchaser, :walkup, :purchasemethod, :ship_to_purchaser

  delegate :purchase_medium, :to => :purchasemethod

  # errors

  class Order::OrderFinalizeError < StandardError ; end
  class Order::NotReadyError < Order::OrderFinalizeError ; end
  class Order::SaveRecipientError < Order::OrderFinalizeError ; end
  class Order::SavePurchaserError < Order::OrderFinalizeError ; end
  class Order::PaymentFailedError < Order::OrderFinalizeError ; end

  # merging customers
  def self.foreign_keys_to_customer
    [:customer_id, :purchaser_id, :processed_by_id]
  end

  serialize :valid_vouchers, Hash
  serialize :donation_data, Hash
  serialize :retail_items, Array

  def initialize(*args)
    @purchase_args = {}
    super
  end

  after_initialize :unserialize_items

  private

  def unserialize_items
    self.donation_data ||= {}
    unless donation_data.empty?
      @donation = Donation.new(:amount => donation_data[:amount], :account_code_id => donation_data[:account_code_id], :comments => donation_data[:comments])
    end
    self.valid_vouchers ||= {}
    self.retail_items ||= []
  end

  def prepare_vouchers_from_valid_vouchers
    vouchers = []
    valid_vouchers.each_pair do |valid_voucher_id, quantity|
      vv = ValidVoucher.find(valid_voucher_id)
      vv.customer = processed_by
      vouchers += vv.instantiate(quantity)
    end
    vouchers.flatten!
    # if this is a walkup order, mark the vouchers as walkup
    vouchers.each do |v|
      v.walkup = self.walkup?
    end
    vouchers
  end

  def add_items_to_order(vouchers)
    self.items += vouchers
    self.items += [ donation ] if donation
    self.items += retail_items if retail_items
    self.items.each do |i|
      i.processed_by = self.processed_by
      # for retail item, comment is name of item, so we don't overwrite that.
      i.comments = self.comments unless i.kind_of?(RetailItem)
    end
  end

  def check_purchaser_info
    # walkup orders only need purchaser & recipient info to point to walkup
    #  customer, but regular orders need full purchaser & recipient info.
    if walkup?
      errors.add(:base, "Walkup order requires purchaser & recipient to be walkup customer") unless
        (purchaser == Customer.walkup_customer && customer == purchaser)
    else
      errors.add(:base, "Purchaser information is incomplete: #{purchaser.errors.full_messages.join(', ')}") if
        purchaser.kind_of?(Customer) && !purchaser.valid_as_purchaser?
      errors.add(:base, 'No recipient information') unless customer.kind_of?(Customer)
      errors.add(:customer, customer.errors.as_html) if customer.kind_of?(Customer) && !customer.valid_as_gift_recipient?
    end
  end

  public

  scope :for_customer_reporting, ->() {
    includes(:vouchers => [:customer, :showdate,:vouchertype]).
    includes(:donations => [:customer, :account_code]).
    includes(:processed_by).
    includes(:purchaser).
    includes(:purchasemethod).
    includes(:items).
    includes(:customer)
  }

  scope :for_transactions_reporting, ->() {
    includes(:purchasemethod).
    includes(:items).
    includes(:customer).
    includes(:donations => :account_code).
    includes(:vouchers => [:showdate,:vouchertype])
  }
    
  def self.to_csv
    attribs = %w(id sold_on purchaser_name purchase_medium total_price item_descriptions)
    CSV.generate(:headers => true) do |csv|
      csv << attribs
      all.each { |o| csv << attribs.map { |att| o.send att }}
    end
  end

  def customer_name ; customer.full_name ; end
  def purchaser_name ; purchaser.full_name ; end

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
    valid_vouchers.empty? && donation.nil? && retail_items.empty?
  end

  def add_with_checking(valid_voucher, number, promo_code)
    adjusted = valid_voucher.adjust_for_customer(promo_code)
    if number <= adjusted.max_sales_for_this_patron
      self.add_tickets(valid_voucher, number)
    else
      self.errors.add(:base,adjusted.explanation)
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
    self.donation_data[:comments] = d.comments
    @donation = d
  end

  def add_retail_item(r)
    self.retail_items << r if r
  end

  def ticket_count
    completed? ? vouchers.count : valid_vouchers.values.map(&:to_i).sum
  end

  def item_count ; ticket_count + (include_donation? ? 1 : 0) + retail_items.size; end

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
      ValidVoucher.find(valid_vouchers.keys).any? { |vv| vv.vouchertype.category == 'revenue' }
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

  def total_price
    return items.map(&:amount).sum if completed?
    total = self.donation.try(:amount).to_f + self.retail_items.map(&:amount).sum
    valid_vouchers.each_pair do |vv_id, qty|
      total += ValidVoucher.find(vv_id).price * qty
    end
    total
  end

  def walkup_confirmation_notice
    notice = []
    notice << "#{'$%.02f' % donation.amount} donation" if include_donation?
    if include_vouchers?
      notice << "#{ticket_count} ticket" + (ticket_count > 1 ? 's' : '')
    end
    message = notice.join(' and ')
    if total_price.zero?
      message = "Issued #{message} as zero-revenue order"
    else
      if include_vouchers?
        message << " (total #{'$%.02f' % total_price})"
      end
      message << " paid by #{ActiveSupport::Inflector::humanize(purchase_medium)}"
    end
    message
  end

  def summary
    (items.map(&:one_line_description) << self.comments).join("\n")
  end

  def summary_for_audit_txn
    summary = items.map(&:description_for_audit_txn)
    summary << comments unless comments.blank?
    summary << "Stripe ID #{authorization}" unless authorization.blank?
    summary.join('; ')
  end

  def each_voucher
    valid_vouchers.each_pair do |id,num|
      v = ValidVoucher.find(id)
      num.times { yield v }
    end
  end

  def completed? ;  persisted?  &&  !sold_on.blank? ; end

  def ready_for_purchase?
    errors.clear
    errors.add(:base, 'Shopping cart is empty') if cart_empty?
    errors.add(:base, 'No purchaser information') unless purchaser.kind_of?(Customer)
    errors.add(:base, "You must specify the enrollee's name for classes") if
      contains_enrollment? && comments.blank?
    check_purchaser_info unless processed_by.try(:is_boxoffice)
    if purchasemethod.kind_of?(Purchasemethod)
      errors.add(:base,'Invalid credit card transaction') if
        purchase_args && purchase_args[:credit_card_token].blank?       &&
        purchase_medium == :credit_card
      errors.add(:base,'Zero amount') if
        total_price.zero? && purchase_medium != :cash
    else
      errors.add(:base,'No payment method specified')
    end
    errors.add(:base, 'No information on who processed order') unless processed_by.kind_of?(Customer)
    errors.empty?
  end

  def finalize!(sold_on_date = Time.now)
    raise Order::NotReadyError unless ready_for_purchase?

    begin
      transaction do
        vouchers = prepare_vouchers_from_valid_vouchers()
        add_items_to_order(vouchers)
        customer.add_items(vouchers)
        customer.add_items(retail_items)
        purchaser.add_items([donation]) if donation
        customer.save!
        purchaser.save!
        self.sold_on = sold_on_date
        self.save!
        if purchase_medium == :credit_card
          Store.pay_with_credit_card(self) or raise(Order::PaymentFailedError, self.errors.as_html)
        end
      end
    rescue ValidVoucher::InvalidRedemptionError => e
      raise Order::NotReadyError, e.message
    rescue Order::PaymentFailedError,RuntimeError => e
      raise e
    end
  end

  def refundable?
    completed? &&
      (refundable_to_credit_card? || purchase_medium != :credit_card)
  end

  def refundable_to_credit_card?
    completed? && purchase_medium == :credit_card  && !authorization.blank?
  end

  def gift?
    purchaser  &&  customer != purchaser
  end

  def ship_to
    if gift? && ship_to_purchaser  then purchaser else customer end
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
