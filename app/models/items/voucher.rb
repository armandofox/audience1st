class Voucher < Item
  belongs_to :showdate

  class ReservationError < StandardError ;  end

  belongs_to :vouchertype
  validates_associated :vouchertype
  delegate :category, :to => :vouchertype

  validate :checkin_requires_reservation
  validates_presence_of :seat, :if => :for_reserved_seating_performance?
  validate :existing_seat, :if => :reserved?
  validates_uniqueness_of :seat, :scope => :showdate_id, :allow_blank => true, :message => '%{value} is already taken'

  delegate :gift?, :ship_to, :to => :order # association is via Item (ancestor class)

  # when a bundle voucher is cancelled, we must also cancel all its
  # constituent vouchers.  This method therefore extends the superclass method.

  has_many :bundled_vouchers, :class_name => 'Voucher', :foreign_key => 'bundle_id'

  private
  
  def checkin_requires_reservation
    errors.add(:base, 'Unreserved voucher cannot be checked in') unless (!checked_in or reserved?)
  end

  def existing_seat
    errors.add(:seat, 'does not exist for this performance') unless
      showdate.can_accommodate?(seat)
      ! showdate.has_reserved_seating?  || seat.blank?  || showdate.seatmap.includes_seat?(seat)
  end

  public

  def self.cancel_multiple!(vchs, num, by_whom)
    to_cancel = vchs.take(num)
    to_leave_reserved = vchs.drop(num)
    preserved_comments = vchs.map(&:comments).compact.
      map { |c| c.split(/\s*;\s*/) }.flatten.
      uniq.join('; ')
    Voucher.transaction do
      to_leave_reserved.each do |v|
        v.update_attributes!(:comments => preserved_comments)
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

  def self.combined_comments(vouchers)
    vouchers.map(&:comments).reject(&:blank?).map do |c|
      c.split(/\s*;\s*/)
    end.flatten.uniq.join('; ')
  end
  
  def self.seats_for(vouchers)
    if vouchers.any? { |v| ! v.seat.blank? }
      vouchers.map(&:seat).compact.map(&:to_s).sort.join(', ')
    else
      vouchers.size.to_s
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

  # scopes that hide implementation of category
  scope :comp, -> { joins(:vouchertype).merge(Vouchertype.of_categories('comp')) }
  scope :revenue, -> { joins(:vouchertype).merge(Vouchertype.of_categories('revenue')) }


  scope :advance_sales, -> { where.not(:customer_id => Customer.walkup_customer.id).includes(:customer,:order) }
  scope :walkup_sales, -> { where(:customer_id => Customer.walkup_customer.id) }
  scope :checked_in, -> { where(:checked_in => true) }
  
  scope :valid_for_showdate, ->(showdate) {
    includes(:vouchertype => :valid_vouchers).
    where('valid_vouchers.showdate_id' => showdate.id)
  }

  # count the number of subscriptions for a given season
  def self.subscription_vouchers(year)
    season_start = Time.current.at_beginning_of_season(year)
    v = Vouchertype.subscription_vouchertypes(year)
    v.map { |t| [t.name, t.price.round, Voucher.where(:finalized => true, :vouchertype_id => t.id).count] }
  end

  def item_description
    vouchertype.name_with_season << 
      (showdate ?
      ": #{showdate.printable_name}" :
      (if bundle? then '' else ' (open)' end))
  end

  # accessors and convenience methods: many are delegated to Vouchertype

  delegate(
    :name,  :season,
    :changeable?, :valid_now?, :bundle?, :subscription?, :subscriber_voucher?,
    :included_vouchers, :num_included_vouchers,
    :unique_showdate,
    :to => :vouchertype)

  scope :open, -> { where(:checked_in => false).where(:showdate => nil) }

  def unreserved? ; showdate_id.to_i.zero? end
  def reserved? ; !(unreserved?) ; end
  def for_reserved_seating_performance?
    reservable? && showdate && showdate.has_reserved_seating?
  end
  def reservable? ; !bundle? && unreserved? && valid_today? ;  end
  def reserved_show ; (showdate.name if reserved?).to_s ;  end
  def reserved_date ; (showdate.printable_name if reserved?).to_s ; end
  def date ; self.showdate.thedate if self.reserved? ; end

  # return the "show" associated with a voucher.  If a regular voucher,
  # it's the show the voucher is associated with. If a bundle voucher,
  # it's the name of the bundle.
  def show ;  showdate ? showdate.show : nil ; end

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
      s = sprintf("$%6.2f  %s\n         %s %s", amount, showdate.printable_name, name, seat)
      s << "\n         Notes: #{comments}" unless comments.blank?
    else
      s = sprintf("$%6.2f  %s", amount, name)
    end
    s
  end

  def description_for_report
    vouchertype.name
  end

  def description_for_audit_txn
    sprintf("%.2f #{vouchertype.name} (%s) [#{id}]", amount,
      (reserved? ? showdate.printable_name : 'open'))
  end
  
  def inspect
    if vouchertype_id.nil?
      sprintf("%d (No vouchertype)", (new_record? ? object_id : id))
    else
      s = sprintf("%d #{vouchertype.name}", (new_record? ? object_id : id))
      if bundle?
        s += sprintf("\n  <%s>,\n", bundled_vouchers.map(&:to_s).join("\n   "))
      end
      s
    end
  end

  # constructors


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

  def redeemable_showdates(ignore_cutoff = false)
    valid_vouchers = vouchertype.valid_vouchers.includes(:showdate).order('showdates.thedate').for_shows
    if ignore_cutoff
      valid_vouchers
    else
      # make sure advance reservations and other constraints fulfilled
      valid_vouchers.map(&:adjust_for_customer_reservation).delete_if { |v| v.explanation =~ /in the past/i }

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

  # BUG there should not be 3 separate methods here
  
  def reserve_for(desired_showdate, processor, new_comments='')
    if reserved?
      errors.add :base,"This ticket is already holding a reservation for #{reserved_date}." and return nil
      raise ReservationError
    end
    redemption = valid_voucher_adjusted_for processor,desired_showdate
    if processor.is_boxoffice || redemption.max_sales_for_this_patron > 0
      reserve!(desired_showdate, new_comments)
    else
      errors.add :base,redemption.explanation
      raise ReservationError
    end
  end
  def reserve(showdate,logged_in_customer,comments='')
    self.showdate = showdate
    self.processed_by = logged_in_customer
    self.comments = comments
    self
  end
  def reserve!(desired_showdate, new_comments='')
    update_attributes!(:comments => new_comments, :showdate => desired_showdate)
  end

  #
  # BUG there should not be both #unreserve and #cancel - what is the difference??
  # 
  def unreserve
    self.showdate = nil
    self.seat = nil
    self.checked_in = false
    save!
  end
  def cancel(logged_in = Customer.walkup_customer.id)
    save_showdate = self.showdate.clone
    self.showdate = nil
    self.checked_in = false
    self.seat = nil
    if (self.save)
      save_showdate
    else
      nil
    end
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
