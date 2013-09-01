class Voucher < Item
  require 'ruport'
  acts_as_reportable
  
  belongs_to :showdate
  belongs_to :vouchertype
  belongs_to :gift_purchaser, :class_name => 'Customer'

  validates_presence_of :vouchertype_id
  # provide a handler to be called when customers are merged.
  # Transfers the vouchers from old to new id, and also changes the
  # values of processed_by field, which is really a customer id.
  # Returns number of actual voucher records transferred.

  # after destroying a bundle voucher, destroy its constituents
  after_destroy do |voucher|
    if voucher.bundle? && voucher.id != 0
      Voucher.delete_all("bundle_id = #{voucher.id}")
    end
  end

  # class methods

  def expiration_date ; Time.at_end_of_season(self.season) ; end

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id, :gift_purchaser_id]
  end
  
  # count the number of subscriptions for a given season
  def self.subscription_vouchers(year)
    season_start = Time.now.at_beginning_of_season(year)
    v = Vouchertype.subscription_vouchertypes(year)
    v.map { |t| [t.name, t.price.round, Voucher.count(:all, :conditions => "vouchertype_id = #{t.id}")] }
  end

  # methods to support reporting functions
  def self.sold_between(from,to)
    sql = %{
        SELECT DISTINCT v.*
        FROM items v JOIN vouchertypes vt ON v.vouchertype_id=vt.id WHERE
        (v.sold_on BETWEEN ? AND ?) AND 
        v.customer_id !=0 AND 
        (v.showdate_id > 0 OR (vt.category='bundle' AND vt.subscription=1))
    }
    Voucher.find_by_sql([sql,from,to])
  end

  # accessors and convenience methods

  # many are delegated to Vouchertype

  delegate(
    :name, :price, :season, :account_code,
    :changeable?, :valid_now?, :bundle?, :subscription?, :subscriber_voucher?,
    :to => :vouchertype)
  def amount ; vouchertype.price ; end
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
  
  def purchasemethod_reportable ; purchasemethod.description ; end

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

  def one_line_description
    if reserved?
      s = sprintf("$%6.2f  %s\n         %s - ticket \##{id}",
        price, showdate.printable_name, name)
      s << "\n         Notes: #{comments}" unless comments.blank?
    else
      s = sprintf("$%6.2f  %s - voucher \##{id}", price, name)
    end
    s
  end

  def to_s
    sprintf("%6d sd=%-15.15s own=%s vtype=%s (%3.2f) %s%s%s] extkey=%-10s",
            id,
            (showdate ? (showdate.printable_name[-15..-1] rescue "--") : 'OPEN'),
            (customer ? customer.to_s : 'NONE'),
            (vouchertype.name[0..10] rescue ""),
            (vouchertype.price.to_f rescue 0.0),
            ((vouchertype.subscription? ? "S" : "s") rescue "-"),
            ((vouchertype.bundle?? "B": "b") rescue "-"),
            ((vouchertype.offer_public ? "P" : "p") rescue "-"),
            external_key)
  end

  # constructors

  def self.new_from_vouchertype(vt,args={})
    vt = Vouchertype.find(vt) unless vt.kind_of?(Vouchertype)
    args[:purchasemethod] ||= Purchasemethod.default
    vt.vouchers.build({
        :fulfillment_needed => vt.fulfillment_needed,
        :sold_on => Time.now,
        :category => vt.category}.merge(args))
  end


  # return a voucher object that can be added to a shopping cart.
  # Fields like customer_id will be bound when voucher is actualy
  # purchased, and only then is it recorded permanently

  def self.anonymous_voucher_for(showdate,vouchertype,promocode=nil,comment=nil)
    showdate = showdate.kind_of?(Showdate) ? showdate.id : showdate.to_i
    vouchertype = vouchertype.kind_of?(Vouchertype) ? vouchertype.id : vouchertype.to_i
    Voucher.new_from_vouchertype(vouchertype,
                                 :showdate_id => showdate,
                                 :promo_code => promocode,
                                 :comments => comment,
                                 :purchasemethod_id => Purchasemethod.get_type_by_name('web_cc'))
  end

  def self.anonymous_bundle_for(vouchertype)
    v = Voucher.new_from_vouchertype(vouchertype,
                                     :purchasemethod_id => Purchasemethod.get_type_by_name('web_cc'))
  end

  def add_comment(comment)
    self.comments = (self.comments.blank? ? comment : [self.comments,comment].join('; '))
  end

  def transfer_to_customer(c)
    if c.kind_of?(Customer) && !c.new_record?
      self.update_attribute(:customer_id, c.id)
      return c
    else
      return nil
    end
  end
  
  def reserve_if_only_one_showdate
    valid_vouchers = vouchertype.valid_vouchers
    if !bundle? && unreserved?  &&  valid_vouchers.length == 1
      self.reserve_for(valid_vouchers.first.showdate,
        self.processed_by_id,
        'Automatic reservation since ticket valid for only a specific show date',
        :ignore_cutoff => true)
    end
  end
  protected :reserve_if_only_one_showdate
  
  def add_to_customer(c)
    begin
      c.vouchers << self
      if self.bundle?
        purch_bundle = Purchasemethod.get_type_by_name('bundle')
        self.vouchertype.get_included_vouchers.each do |type, qty|
          1.upto qty do
            c.vouchers <<
              Voucher.new_from_vouchertype(type,
              :bundle_id => self.id,
              :purchasemethod_id => purch_bundle,
              :processed_by_id => self.processed_by_id)
          end
        end
      end
      # reserve any vouchers that are valid on a single date only
      c.vouchers.map(&:reserve_if_only_one_showdate)
      c.save!
    rescue Exception => e
      c.reload
      return [nil,e.backtrace]
    end
    return [true,self]
  end

  def valid_for_date?(dt) ; dt.to_time <= expiration_date ; end
  def valid_today? ; valid_for_date?(Time.now) ; end

  def validity_dates_as_string
    fmt = '%m/%d/%y'
    if (ed = self.expiration_date)
      "until #{ed.strftime(fmt)}"
    else
      "for all dates"
    end
  end


  # this should probably be eliminated and the function call inlined to wherever
  # this is called from.
  def numseats_for_showdate(sd,args={})
    unless self.valid_for_date?(sd.thedate)
      AvailableSeat.no_seats(self,sd,"Voucher only valid #{self.validity_dates_as_string}")
    else
      ValidVoucher.numseats_for_showdate_by_vouchertype(sd, self.customer,
                                                        self.vouchertype,
                                                        :ignore_cutoff => args[:ignore_cutoff],
                                                        :redeeming => args[:redeeming])
    end
  end

  def redeemable_showdates(ignore_cutoff = false)
    if ignore_cutoff
      vouchertype.valid_vouchers
    else
      # make sure advance reservations and other constraints fulfilled
      vouchertype.valid_vouchers.map(&:adjust_for_customer_reservation)
    end
  end
  def redeemable_for_show?(show,ignore_cutoff = false)
    show = Show.find(show, :include => :showdates) unless show.kind_of?(Show)
    show.showdates.map { |sd| self.numseats_for_showdate(sd,:ignore_cutoff=>ignore_cutoff,:redeeming=>true) }.select { |av| av.howmany > 0 }
  end


  def reserve_for(desired_showdate, logged_in_id, comments='', opts={})
    logged_in_customer = Customer.find(logged_in_id)
    if reserved?
      comments = "This ticket is already holding a reservation for #{reserved_date}."
      return nil
    end
    unless (redemption = ValidVoucher.find_by_showdate_id_and_vouchertype_id(desired_showdate.id, vouchertype_id))
      self.comments = 'This ticket is not valid for the selected performance.'
      return false
    end
    redemption = redemption.adjust_for_customer_reservation
    if redemption.max_sales_for_type > 0 || opts[:ignore_cutoff]
      self.comments = comments
      reserve(desired_showdate, logged_in_customer)
      a = Txn.add_audit_record(:txn_type => 'res_made',
        :customer_id => self.customer.id,
        :logged_in_id => logged_in_id,
        :show_id => self.showdate.show.id,
        :showdate_id => showdate_id,
        :voucher_id => self.id)
      return a
    else
      self.comments = redemption.explanation
      return false
    end
  end

  def can_be_changed?(who = Customer.generic_customer)
    unless who.kind_of?(Customer)
      who = Customer.find(who) rescue Customer.generic_customer
    end
    return (who.is_walkup) ||
      (changeable? && valid_now? && within_grace_period?)
  end

  def reserved_for_show?(s) ; reserved && (showdate.show == s) ;  end
  def reserved_for_showdate?(sd) ;  reserved && (showdate == sd) ;  end
  def within_grace_period?
    unreserved? ||
      (Time.now < (showdate.thedate - Option.cancel_grace_period.minutes))
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
    update_attributes!(:showdate_id => 0, :checked_in => false)
    self
  end
  def reserve(showdate,logged_in_customer)
    self.showdate = showdate
    self.processed_by = logged_in_customer
    self
  end
  def self.transfer_multiple(vouchers, showdate, logged_in_customer)
    Voucher.transaction do
      vouchers.each do |v|
        v.unreserve
        v.reserve(showdate, logged_in_customer)
        v.save! unless v.new_record?
      end
    end
  end
  def self.destroy_multiple(vouchers, logged_in_customer)
    Voucher.transaction do
      vouchers.each { |v| v.destroy }
    end
  end

  def cancel(logged_in = Customer.generic_customer.id)
    save_showdate = self.showdate.clone
    self.showdate_id = 0
    if (self.save)
      save_showdate
    else
      nil
    end
  end

end
