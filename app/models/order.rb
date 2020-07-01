class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchaser, :class_name => 'Customer'
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :ticket_sales_import # only for orders imported from external vendor (eg TodayTix)
  has_many :items, :autosave => true, :dependent => :destroy
  has_many :vouchers, :autosave => true,  :dependent => :destroy
  has_many :donations, :autosave => true, :dependent => :destroy
  has_many :retail_items, :autosave => true, :dependent => :destroy

  attr_accessor :purchase_args
  attr_accessor :comments
  attr_reader :donation

  attr_accessible :comments, :processed_by, :customer, :purchaser, :walkup, :purchasemethod, :ship_to_purchaser, :external_key

  # errors

  class Order::CannotAddItemError < StandardError ; end
  class Order::NotPersistedError < StandardError ; end

  class Order::OrderFinalizeError < StandardError ; end
  class Order::NotReadyError < Order::OrderFinalizeError ; end
  class Order::SaveRecipientError < Order::OrderFinalizeError ; end
  class Order::SavePurchaserError < Order::OrderFinalizeError ; end
  class Order::PaymentFailedError < Order::OrderFinalizeError ; end

  # merging customers
  def self.foreign_keys_to_customer
    [:customer_id, :purchaser_id, :processed_by_id]
  end

  validates_uniqueness_of :external_key, :allow_blank => true, conditions: -> { where.not(:sold_on => nil) }

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

  def check_purchaser_info
    # walkup orders only need purchaser & recipient info to point to walkup
    #  customer, but regular orders need full purchaser & recipient info.
    if walkup?
      errors.add(:base, "Walkup order requires purchaser & recipient to be walkup customer") unless
        (purchaser == Customer.walkup_customer && customer == purchaser)
    else
      errors.add(:base, 'No purchaser information') and return unless purchaser.kind_of?(Customer)
      errors.add(:base, "Purchaser information is incomplete: #{purchaser.errors.full_messages.join(', ')}") unless purchaser.valid_as_purchaser?
      errors.add(:base, 'No recipient information') and return unless customer.kind_of?(Customer)
      errors.add(:customer, customer.errors.as_html) if (gift? && ! customer.valid_as_gift_recipient?)
    end
  end

  public

  scope :completed, ->() { where('sold_on IS NOT NULL') }
  scope :abandoned_since, ->(since) { where('sold_on IS NULL').where('updated_at < ?', since) }
  
  scope :for_customer_reporting, ->() {
    includes(:vouchers => [:customer, :showdate,:vouchertype]).
    includes(:donations => [:customer, :account_code]).
    includes(:processed_by).
    includes(:purchaser).
    includes(:items).
    includes(:customer)
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

  def purchase_medium ; Purchasemethod.get(purchasemethod).purchase_medium ; end
  
  def self.new_from_donation(amount, account_code, donor)
    order = Order.new(:purchaser => donor, :customer => donor)
    order.add_donation(Donation.from_amount_and_account_code_id(amount, account_code.id))
    order
  end

  def add_comment(arg)
    self.comments ||= ''
    self.comments += arg
  end

  def clear_contents!
    self.vouchers.destroy_all
    self.donation_data = {}
  end

  def cart_empty?
    ticket_count.zero? &&  donation.nil? && retail_items.empty?
  end

  def add_nonticket_items_from_params(params)
    return if params.nil? || params.empty?
    params.each_pair do |vv_id,qty|
      vv = ValidVoucher.find(vv_id)
      qty.to_i.times { add_retail_item(RetailItem.from_vouchertype vv.vouchertype) }
    end
  end

  def add_tickets_from_params(valid_voucher_params, customer, promo_code: '', seats: [])
    return unless valid_voucher_params
    seats2 = seats.dup
    total_tickets = valid_voucher_params.map do |id,count|
      ValidVoucher.find(id).vouchertype.reservable? ? count.to_i  : 0
    end.sum
    saleable_seats = if (sd = ValidVoucher.find(valid_voucher_params.keys.first).showdate) then sd.saleable_seats_left else 0 end
    if !seats2.empty?
      # error unless number of seats matches number of requested tickets
      self.errors.add(:base, I18n.translate('store.errors.not_enough_seats_selected', :tickets => total_tickets, :seats => seats2.length)) and return unless total_tickets == seats2.length
    end
    raise Order::NotPersistedError unless persisted?
    valid_voucher_params.each_pair do |vv_id, qty|
      qty = qty.to_i
      next if qty.zero?
      vv = ValidVoucher.find(vv_id)
      vv.supplied_promo_code = promo_code.to_s
      vv.customer = customer || self.processed_by || Customer.anonymous_customer
      seats = seats2.slice!(0,qty)
      # is this order-placer allowed to exercise this redemption?
      redemption = vv.adjust_for_customer
      if (vv.customer.try(:is_boxoffice) || redemption.max_sales_for_this_patron >= qty)
        add_tickets_without_capacity_checks(vv, qty, seats)
      else
        self.errors.add(:base, I18n.translate('store.errors.not_enough_seats', :count => saleable_seats))
      end
    end
  end

  def add_open_vouchers_without_capacity_checks(vouchertype, number)
    raise Order::NotPersistedError unless persisted?
    new_vouchers = VoucherInstantiator.new(vouchertype).from_vouchertype(number)
    self.vouchers += new_vouchers
    self.save!
  end

  def add_tickets_without_capacity_checks(valid_voucher, number, seats=[])
    raise Order::NotPersistedError unless persisted?
    new_vouchers = VoucherInstantiator.new(valid_voucher.vouchertype).from_vouchertype(number)
    # reserve only if a specific showdate is indicated.  it seems like this method
    # should really take a vouchertype and showdate.
    if valid_voucher.showdate
      begin
        new_vouchers.each_with_index do |v,i|
          v.seat = seats[i] unless seats.empty?
          v.reserve!(valid_voucher.showdate)
        rescue ActiveRecord::RecordInvalid, ReservationError #  reservation couldn't be processed
          self.errors.add(:base, v.errors.full_messages.join(', '))
          v.destroy               # otherwise it'll end up with no order ID and can't be reaped
        end
      end
    end
    if self.errors.empty?       # all vouchers were added OK
      self.vouchers += new_vouchers
      self.save!
    else                        # since order can't proceed, DESTROY all vouchers so not orphaned
      new_vouchers.each { |v| v.destroy if v.persisted? } 
    end
  end
  
  def ticket_count ;       vouchers.size        ; end
  def item_count ; ticket_count + (includes_donation? ? 1 : 0) + retail_items.size; end

  def includes_vouchers?       ; ticket_count > 0  ; end
  def includes_streaming?      ; vouchers.any? { |v| v.showdate.try(&:stream?) } ; end
  def includes_mailable_items? ; items.any? { |v| v.vouchertype.try(:fulfillment_needed?) } ; end
  def includes_enrollment?     ; items.any? { |v| v.showdate.try(:event_type) == 'Class' } ; end
  def includes_nonticket_item? ;  items.any? { |v| v.vouchertype.try(:nonticket?) } ; end
  #def includes_bundle?         ;  vouchers.any?(&:bundle?)     ;  end
  #def includes_regular_vouchers? ; vouchers.any? { |v| !v.bundle? }   ; end
  #def includes_reserved_vouchers? ; vouchers.any?(&:reserved?) ; end
  def includes_bundle?         ;  items.any? { |v| v.vouchertype.try(:bundle?) }  ;  end
  def includes_regular_vouchers? ; items.any? { |v| v.kind_of?(Voucher) && !v.bundle? } ;  end
  def includes_reserved_vouchers? ; items.any? { |v| v.kind_of?(Voucher) && v.reserved? } ; end


  def add_donation(d) ; self.donation = d ; end
  def donation=(d)
    self.donation_data[:amount] = d.amount
    self.donation_data[:account_code_id] = d.account_code_id
    self.donation_data[:comments] = d.comments
    @donation = d
  end
  def includes_donation?
    if completed?
      items.any? { |v| v.kind_of?(Donation) }
    else
      !donation.nil?
    end
  end

  def add_retail_item(r)
    raise Order::NotPersistedError unless persisted?
    self.retail_items << r if r
  end


  def ok_for_guest_checkout?
    # basically, the ONLY thing you can guest checkout for is single-ticket purchases for yourself.
    ! (gift? || includes_mailable_items? || includes_bundle? || includes_enrollment? || includes_nonticket_item?)
  end

  def total_price
    if completed?
      items.map(&:amount).sum
    else
      self.donation.try(:amount).to_f +
        self.retail_items.map(&:amount).sum +
        self.vouchers.sum(:amount)
    end
  end

  def walkup_confirmation_notice
    notice = []
    notice << "#{'$%.02f' % donation.amount} donation" if includes_donation?
    if includes_vouchers?
      notice << "#{ticket_count} ticket" + (ticket_count > 1 ? 's' : '')
    end
    if ! retail_items.empty?
      nonticket_count = retail_items.size
      notice << "#{nonticket_count} retail item" + (nonticket_count > 1 ? 's' : '')
    end
    message = notice.join(' and ')
    if total_price.zero?
      message = "Issued #{message} as zero-revenue order"
    else
      message << " (total #{'$%.02f' % total_price})"
      message << " paid by #{ActiveSupport::Inflector::humanize(purchase_medium)}"
    end
    message
  end

  def summary(separator = "\n")
    summary = []
    vouchers, nonvouchers = items.partition { |i| i.kind_of?(Voucher) }
    vouchers.group_by { |v| [v.vouchertype, v.showdate] }.each_pair do |for_show,vouchers|
      summary << "#{vouchers.count} @ #{vouchers.first.one_line_description}"
    end
    if vouchers.any? { |v| !v.seat.blank? }
      summary << "Seats: #{Voucher.seats_for(vouchers)}"
    end
    summary += nonvouchers.map(&:one_line_description)
    summary << self.comments
    summary << streaming_access_instructions if includes_streaming?
    summary.join(separator)
  end

  def summary_for_audit_txn
    summary = items.map(&:description_for_audit_txn)
    summary << comments unless comments.blank?
    summary << "Stripe ID #{authorization}" unless authorization.blank?
    summary.join('; ')
  end

  def streaming_access_instructions
    # this is almost certainly a Demeter violation...but not sure how to make better
    vouchers.first.showdate.access_instructions
  end
  
  def collect_notes
    # collect the showdate-specific (= show-specific) notes in the order
    items.map(&:showdate).compact.uniq.map(&:patron_notes).compact
  end

  def completed? ;  persisted?  &&  !sold_on.blank? ; end

  def comment_prompt
    if (! includes_vouchers? || includes_bundle? || gift? || includes_streaming?) then nil
    elsif includes_enrollment?  then {
        prompt: 'Who is attending the class?',
        placeholder: "Enrollee's name"
      }
    else {
        prompt: 'Is someone other than the purchaser picking up the tickets?',
        placeholder: "If yes, attendee's name"
      }
    end
  end

  def ready_for_purchase?
    errors.clear
    errors.add(:base, 'Shopping cart is empty') if cart_empty?
    errors.add(:base, "You must specify the enrollee's name for classes") if
      includes_enrollment? && comments.blank?
    check_purchaser_info unless processed_by.try(:is_boxoffice)
    if Purchasemethod.valid_purchasemethod?(purchasemethod)
      errors.add(:base,'Invalid credit card transaction') if
        purchase_args && purchase_args[:credit_card_token].blank?       &&
        purchase_medium == :credit_card
      errors.add(:base,'Zero amount') if
        total_price.zero? && Purchasemethod.must_be_nonzero_amount(purchasemethod)
    else
      errors.add(:base,'No payment method specified')
    end
    errors.add(:base, 'No information on who processed order') unless processed_by.kind_of?(Customer)
    errors.empty?
  end

  def finalize_with_existing_customer_id!(cid,processed_by,sold_on=Time.current)
    self.customer_id = self.purchaser_id = cid
    self.processed_by = processed_by
    self.finalize!(sold_on)
  end
  
  def finalize_with_new_customer!(customer,processed_by,sold_on=Time.current)
    customer.force_valid = true
    self.customer = self.purchaser = customer
    self.finalize!(sold_on)
  end

  def finalize!(sold_on_date = Time.current)
    raise Order::NotReadyError unless ready_for_purchase?
    begin
      transaction do
        self.items += vouchers
        self.items += retail_items
        self.items << donation if donation
        self.items.each do |i|
          i.finalize!
          i.sold_on = sold_on_date
          i.walkup = self.walkup? 
          i.processed_by = self.processed_by
          i.comments = self.comments if i.comments.blank?  && i.kind_of?(Voucher)
        end
        # there is also a direct relationship Customer has-many Items, which we should get rid of...
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
      items.any? { |i| !i.kind_of?(CanceledItem) } # in case all items were ALREADY refunded and now marked as canceled
      (refundable_to_credit_card? || Purchasemethod.get(purchasemethod).refundable?)
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
    Purchasemethod.get(purchasemethod).description
  end

  def item_descriptions
    items.map(&:item_description).
      inject(Hash.new(0)) { |h,v| h[v]+=1 ; h }.
      map { |item,count| ("%3d @ #{item}" % count) }.
      join("\n")
  end

end
