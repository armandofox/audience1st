class Voucher < Item
  require 'csv'
  belongs_to :showdate
  belongs_to :vouchertype

  class ReservationError < StandardError ;  end
  validates_presence_of :vouchertype_id

  validates_inclusion_of :category, :in => Vouchertype::CATEGORIES

  validate :checkin_requires_reservation

  def checkin_requires_reservation
    !checked_in or reserved?
  end
  private :checkin_requires_reservation

  delegate :gift?, :ship_to, :to => :order

  # when a bundle voucher is cancelled, we must also cancel all its
  # constituent vouchers.  This method therefore extends the superclass method.

  has_many :bundled_vouchers, :class_name => 'Voucher', :foreign_key => 'bundle_id'

  def self.cancel_multiple!(vchs, num, by_whom)
    to_cancel = vchs[0,num]
    to_leave_reserved = vchs[num + 1]
    preserve_comments = to_cancel.map(&:comments)
    Voucher.transaction do
      if to_leave_reserved && !preserve_comments.blank?
        preserve_comments.unshift(to_leave_reserved.comments.to_s)
        to_leave_reserved.update_attributes!(:comments => preserve_comments.join('; '))
      end
      to_cancel.each do |v|
        Txn.add_audit_record(:txn_type => 'res_cancl',
          :customer_id => v.customer.id,
          :logged_in_id => by_whom.id,
          :showdate_id => v.showdate_id,
          :show_id => v.showdate.show_id,
          :voucher_id => v.id)
        v.cancel(by_whom)
      end
    end
  end

  def cancel!(by_whom)
    result = super # cancel the main voucher
    bundled_vouchers.each { |v| v.cancel!(by_whom) }
    result
  end

  def part_of_bundle? ; bundle_id != 0 ; end

  # similarly, a voucher that is part of a bundle is not individually cancelable

  def cancelable?
    !part_of_bundle? &&  super
  end
    
  # class methods

  def expiration_date ; Time.at_end_of_season(self.season) ; end

  # scopes for reporting
  scope :for_unfulfilled_orders, -> {
    includes(:customer, :vouchertype, :order).
    references(:customers, :orders).
    where.not(:orders => {:sold_on => nil}).
    where(:fulfillment_needed => true).
    order('customers.last_name,orders.sold_on')
  }

  # scopes that hide implementation of category
  scope :comp, -> { where(:category => 'comp') }
  scope :revenue, -> { where(:category => 'revenue') }
  scope :subscriber, -> { where(:category => 'subscriber') }
  scope :advance_sales, -> { where.not(:customer_id => Customer.walkup_customer.id).includes(:customer,:order) }
  scope :walkup_sales, -> { where(:customer_id => Customer.walkup_customer.id) }
  scope :checked_in, -> { where(:checked_in => true) }
  
  # count the number of subscriptions for a given season
  def self.subscription_vouchers(year)
    season_start = Time.current.at_beginning_of_season(year)
    v = Vouchertype.subscription_vouchertypes(year)
    v.map { |t| [t.name, t.price.round, Voucher.where('vouchertype_id = ?',t.id).count] }
  end

  def item_description
    vouchertype.name_with_season << 
      (showdate ?
      ": #{showdate.printable_name}" :
      (if bundle? then '' else ' (open)' end))
  end

  # accessors and convenience methods

  # many are delegated to Vouchertype

  def self.unfulfilled_orders_to_csv
    CSV.generate(:headers => false) do |csv|
      orders = all.group_by do |v|
        [v.ship_to, v.vouchertype]
      end
      orders.each_pair do |k,v|
        voucher = v[0]
        row = k[0].name_and_address_to_csv
        row << v[0].order.sold_on
        row << v.size           # quantity
        row << k[1].name        # product
        csv << row
      end
    end
  end

  delegate(
    :name,  :season,
    :changeable?, :valid_now?, :bundle?, :subscription?, :subscriber_voucher?,
    :included_vouchers, :num_included_vouchers,
    :unique_showdate,
    :to => :vouchertype)

  scope :open, -> { where(:checked_in => false).where(:showdate => nil) }

  # delegations
  def account_code_reportable ; vouchertype.account_code.name_with_code ; end

  def unreserved? ; showdate_id.to_i.zero?  ;  end
  def reserved? ; !(unreserved?) ; end
  
  def reservable? ; !bundle? && unreserved? && valid_today? ;  end
  def reserved_show ; (showdate.name if reserved?).to_s ;  end
  def reserved_date ; (showdate.printable_name if reserved?).to_s ; end
  def date ; self.showdate.thedate if self.reserved? ; end

  # return the "show" associated with a voucher.  If a regular voucher,
  # it's the show the voucher is associated with. If a bundle voucher,
  # it's the name of the bundle.
  def show ;  showdate ? showdate.show : nil ; end
  def show_or_bundle_name
    show.kind_of?(Show)  ? show.name :
      (vouchertype_id > 0 && vouchertype.bundle? ? vouchertype.name : "??")
  end

  def voucher_description
    if showdate.kind_of?(Showdate)
      showdate.name
    elsif vouchertype.bundle?
      vouchertype.name
    else
      ''
    end
  end
  
  def purchasemethod_reportable ; Purchasemethod.get(purchasemethod).description ; end

  def processed_by_name
    if self.processed_by_id.to_i.zero?
      ""
    elsif (c = Customer.find_by_id(self.processed_by_id))
      c.first_name
    else
      "???"
    end
  end

  # sorting order: by showdate, or by vouchertype_id if same showdate
  def <=>(other)
    self.showdate_id == other.showdate_id ?
    self.vouchertype_id <=> other.vouchertype_id :
      self.showdate <=> other.showdate
  end

  # Sort all reserved vouchers by showdate, then all unreserved ones
  def reservation_status_then_showdate ; reserved? ? -(showdate.thedate.to_i) : -1.0e15 ; end

  def one_line_description
    if reserved?
      s = sprintf("$%6.2f  %s\n         %s", amount, showdate.printable_name, name)
      s << "\n         Notes: #{comments}" unless comments.blank?
    else
      s = sprintf("$%6.2f  %s", amount, name)
    end
    s
  end

  def description_for_audit_txn
    sprintf("%.2f #{vouchertype.name} (%s) [#{id}]", amount,
      (reserved? ? showdate.printable_name : 'open'))
  end
  
  def inspect
    s = sprintf("%d %s", (new_record? ? object_id : id),
      (vouchertype.nil? ? '(nil!)' : vouchertype.name))
    if bundle?
      s += sprintf("\n  <%s>,\n", bundled_vouchers.map(&:inspect).join("\n   "))
    end
    s
  end

  # constructors

  def self.new_from_vouchertype(vt,args={})
    vt = Vouchertype.find(vt) unless vt.kind_of?(Vouchertype)
    vt.vouchers.build({
        :fulfillment_needed => vt.fulfillment_needed,
        :amount => vt.price,
        :account_code => vt.account_code,
        :category => vt.category}.merge(args))
  end

  def add_comment(comment)
    self.comments = (self.comments.blank? ? comment : [self.comments,comment].join('; '))
  end

  def transfer_to_customer(customer)
    cid = customer.id
    Voucher.transaction do
      update_attributes!(:customer_id => cid)
      bundled_vouchers.each { |v| v.update_attributes!(:customer_id => cid) } 
    end
  end

  def valid_today? ; Time.current <= expiration_date ; end

  def validity_dates_as_string
    fmt = '%m/%d/%y'
    if (ed = self.expiration_date)
      "until #{ed.strftime(fmt)}"
    else
      "for all dates"
    end
  end

  def redeemable_for?(showdate, ignore_cutoff=false)
    ours = vouchertype.valid_vouchers.where(:showdate => showdate)
    redeemable = (ours & showdate.valid_vouchers).first
    redeemable.try(:max_sales_for_this_patron)
  end

  def redeemable_showdates(ignore_cutoff = false)
    valid_vouchers = vouchertype.valid_vouchers.includes(:showdate).order('showdates.thedate').for_shows
    if ignore_cutoff
      valid_vouchers
    else
      # make sure advance reservations and other constraints fulfilled
      valid_vouchers.map(&:adjust_for_customer_reservation).delete_if { |v| v.explanation =~ /in the past/i }

    end
  end
  
  def reserve_for(desired_showdate, processor, new_comments='')
    errors.add :base,"This ticket is already holding a reservation for #{reserved_date}." and return nil if reserved?
    redemption = valid_voucher_adjusted_for processor,desired_showdate
    if processor.is_boxoffice || redemption.max_sales_for_this_patron > 0
      reserve!(desired_showdate, new_comments)
      true
    else
      errors.add :base,redemption.explanation
      false
    end
  end

  def can_be_changed?(who = Customer.walkup_customer)
    unless who.kind_of?(Customer)
      who = Customer.find(who) rescue Customer.walkup_customer
    end
    return (who.is_walkup) ||
      (changeable? && valid_now? && within_grace_period?)
  end

  # A voucher is transferable if:
  #  - It is a regular (not part of bundle) voucher, and unreserved
  #  - It is a bundle voucher, and none of its children are reserved
  def transferable?
    !bundle? && !part_of_bundle?  &&  unreserved?  or
      bundle? && bundled_vouchers.all?(&:unreserved?)
  end

  def within_grace_period?
    unreserved? ||
      (Time.current < (showdate.thedate - Option.cancel_grace_period.minutes))
  end

  # Checked in?
  def check_in! ; update_attribute(:checked_in, true) ; self ; end
  def un_check_in! ; update_attribute(:checked_in, false) ; self ; end
  
  # operations on vouchers:
  #
  # reserve(showdate_id, logged_in)
  #  reservation binds it to a showdate and fills in who processed it
  # 
  def unreserve
    self.showdate = nil
    self.checked_in = false
    save!
  end
  def reserve(showdate,logged_in_customer,comments='')
    self.showdate = showdate
    self.processed_by = logged_in_customer
    self.comments = comments
    self
  end

  def self.change_showdate_multiple(vouchers, showdate, logged_in_customer)
    Voucher.transaction do
      vouchers.each do |v|
        v.unreserve
        v.reserve(showdate, logged_in_customer)
        v.save! unless v.new_record?
      end
    end
  end

  def self.transfer_multiple(voucher_ids, to_customer, logged_in_customer)
    total = 0
    begin
      vouchers = voucher_ids.map { |v| Voucher.find v }
      Voucher.transaction do
        vouchers.each do |v|
          v.update_attributes!(:customer => to_customer, :processed_by => logged_in_customer)
          total += 1
          if v.bundle?
            bundled = v.bundled_vouchers
            bundled.each { |b| b.update_attributes!(:customer => to_customer, :processed_by => logged_in_customer) }
            total += bundled.length
          end
        end
      end
    rescue RuntimeError => e
      return nil, e.message
    end
    return true, total
  end

  def cancel(logged_in = Customer.walkup_customer.id)
    save_showdate = self.showdate.clone
    self.showdate = nil
    self.checked_in = false
    if (self.save)
      save_showdate
    else
      nil
    end
  end

  def reserve!(desired_showdate, new_comments='')
    update_attributes(:comments => new_comments, :showdate => desired_showdate)
  end

  def valid_voucher_adjusted_for customer,showdate
    redemption = vouchertype.valid_vouchers.find_by_showdate_id(showdate.id)
    if redemption
      redemption.customer = customer
      redemption = redemption.adjust_for_customer_reservation
    else
      redemption = ValidVoucher.new(:max_sales_for_this_patron => 0,
        :explanation => 'This ticket is not valid for the selected performance.')
    end
  end

end
