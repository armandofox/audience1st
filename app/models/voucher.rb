class Voucher < ActiveRecord::Base
  belongs_to :customer
  belongs_to :showdate
  belongs_to :vouchertype
  belongs_to :purchasemethod
  belongs_to :processed_by, :class_name => 'Customer'
  belongs_to :gift_purchaser, :class_name => 'Customer'

  validates_presence_of :vouchertype
  validates_presence_of :purchasemethod
  validates_presence_of :processed_by_id
  # provide a handler to be called when customers are merged.
  # Transfers the vouchers from old to new id, and also changes the
  # values of processed_by field, which is really a customer id.
  # Returns number of actual voucher records transferred.

  # class methods

  def self.merge_handler(old,new)
    Voucher.update_all("processed_by_id = '#{new}'", "processed_by_id = '#{old}'")
    Voucher.update_all("customer_id = '#{new}'", "customer_id = '#{old}'")
    Voucher.update_all("gift_purchaser_id = '#{new}'", "gift_purchaser_id = '#{old}'")
  end

  # count the number of subscriptions for a given season
  def self.subscription_vouchers(year)
    season_start = Time.now.at_beginning_of_season(year)
    v = Vouchertype.find(:all, :conditions =>"category = 'bundle' AND subscription=1").select { |vt| vt.valid_for_season?(year) }
    v.map { |t| [t.name, t.price.round, Voucher.count(:all, :conditions => "vouchertype_id = #{t.id}")] }
  end

  # methods to support reporting functions
  def self.sold_between(from,to)
    sql = %{
        SELECT DISTINCT v.*
        FROM vouchers v JOIN vouchertypes vt ON v.vouchertype_id=vt.id WHERE
        (v.sold_on BETWEEN ? AND ?) AND 
        v.customer_id !=0 AND 
        (v.showdate_id > 0 OR (vt.category='bundle' AND vt.subscription=1))
    }
    Voucher.find_by_sql([sql,from,to])
  end

  # accessors and convenience methods

  def price ; vouchertype.price ;  end
  def amount ; vouchertype.price ; end

  def reserved? ;   !showdate_id.to_i.zero? ;  end
  def unreserved? ; showdate_id.to_i.zero?  ;  end

  def bundle? ; self.vouchertype.bundle? ; end
  def subscription? ; self.vouchertype.subscription? ; end
  def reservable? ; !bundle? && unreserved? && valid_today? ;  end
  def reserved_show ; (self.showdate.show.name if self.reserved?).to_s ;  end
  def reserved_date ; (self.showdate.printable_date if self.reserved?).to_s ; end
  def date ; self.showdate.thedate if self.reserved? ; end

  # return the "show" associated with a voucher.  If a regular voucher,
  # it's the show the voucher is associated with. If a bundle voucher,
  # it's the name of the bundle.
  def show ;  showdate.show ; end
  def show_or_bundle_name
    show.kind_of?(Show)  ? show.name :
      (vouchertype_id > 0 && vouchertype.bundle? ? vouchertype.name : "??")
  end

  def account_code ; self.vouchertype.account_code ; end

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

  # every time a voucher is saved that belongs to a customer, that customer's
  # subscriber? attribute must be recomputed

  def compute_customer_is_subscriber
    return unless customer_id > 0
    begin
      if (c = Customer.find_by_id(customer_id)).kind_of?(Customer)
        old = c.is_current_subscriber
        new = c.role >= 0 &&
          c.vouchers.detect do |f|
          f.vouchertype && f.vouchertype.subscription? &&
            f.vouchertype.valid_now?
        end
        unless (old == new)
          logger.info("Customer #{c.full_name} (#{c.id}) " <<
                      "subscriber status change from #{old} to #{new} " <<
                      "while saving voucher #{id}")
        end
        c.update_attribute(:is_current_subscriber, new)
      else
        logger.error("Voucher #{id} owned by nonexistent cust #{customer_id}")
      end
    rescue Exception => e
      logger.error("Updating voucher #{id}: #{e.message}")
    end
  end

  def to_s
    sprintf("%6d sd=%-15.15s own=%s vtype=%s (%3.2f) %s%s%s] extkey=%-10d",
            id,
            (showdate_id.zero? ? "OPEN" : (showdate.printable_name[-15..-1] rescue "--")),
            (customer_id.zero? ? "NONE" :
             ("#{customer.last_name[-6..-1]},#{customer.first_name[0..0]}" rescue "?#{customer_id}")),
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
    vt.vouchers.build({:fulfillment_needed => vt.fulfillment_needed,
                       :sold_on => Time.now,
                       :changeable => false,
                       :category => vt.category,
                       :expiration_date => vt.expiration_date}.merge(args))
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



  def self.add_vouchers_for_customer(vtype_id,howmany,cust,purchasemethod_id,showdate_id, comments, bywhom=Customer.generic_customer.id, fulfillment_needed=false,can_change=false,bundle_id=nil)
    vt = Vouchertype.find(vtype_id)
    raise "Number to add must be positive" unless howmany > 0
    raise  "Customer record invalid" unless cust.is_a?(Customer)
    raise "Purchase method is invalid" unless Purchasemethod.find(purchasemethod_id)
    raise "Invalid showdate" unless (showdate_id.zero? or Showdate.find(showdate_id))
    newvouchers = Array.new(howmany) { |v|
      v = Voucher.new_from_vouchertype(vtype_id,
        :purchasemethod_id => purchasemethod_id,
        :comments => comments,
        :fulfillment_needed => fulfillment_needed,
        :processed_by_id => bywhom,
        :customer_id => cust.id,
        :changeable => can_change,
        :bundle_id => bundle_id,
        :showdate_id => showdate_id)
      v.customer = cust
      v.save!
      cust.vouchers << v
      # if this voucher is actually a "bundle", recursively add the
      # bundled vouchers
      # NOTE: fulfillment_needed is ALWAYS FALSE for vouchers included in a bundle!
      if v.bundle?
        can_change = v.vouchertype.subscription?
        purchasemethod_bundle_id = Purchasemethod.get_type_by_name('bundle')
        v.vouchertype.get_included_vouchers.each {  |type, qty|
          if (qty > 0)
            self.add_vouchers_for_customer(type, qty, cust,
              purchasemethod_bundle_id,
              showdate_id, '', bywhom, false, can_change,
              v.id)
          end
        }
      end
      v
    }
    return newvouchers
  end

  def transfer_to_customer(c)
    if c.kind_of?(Customer) && !c.new_record?
      self.update_attribute(:customer_id, c.id)
      return c
    else
      return nil
    end
  end
  
  def add_to_customer(c)
    begin
      c.vouchers << self
      if self.bundle?
        purch_bundle = Purchasemethod.get_type_by_name('bundle')
        Voucher.transaction do
          self.vouchertype.get_included_vouchers.each do |type, qty|
            1.upto qty do
              c.vouchers <<
                Voucher.new_from_vouchertype(type,
                                             :purchasemethod_id => purch_bundle)
            end
          end
        end
      end
      c.save!
    rescue Exception => e
      return [nil,e.message]
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
    self.vouchertype.showdates.map { |sd| self.numseats_for_showdate(sd,:ignore_cutoff=>ignore_cutoff,:redeeming=>true) }.sort
  end

  def redeemable_for_show?(show,ignore_cutoff = false)
    show = Show.find(show, :include => :showdates) unless show.kind_of?(Show)
    show.showdates.map { |sd| self.numseats_for_showdate(sd,:ignore_cutoff=>ignore_cutoff,:redeeming=>true) }.select { |av| av.howmany > 0 }
  end

  def can_be_changed?(who = Customer.generic_customer)
    unless who.kind_of?(Customer)
      who = Customer.find(who) rescue Customer.generic_customer
    end
    if (who.is_walkup)          # admin ?
      return true
    else
      return (changeable? &&
              (expiration_date > Time.now) &&
              (unreserved? ||
               (Time.now < (showdate.thedate - Option.value(:cancel_grace_period).minutes))))
    end
  end

  def reserved_for_show?(s) ; reserved && (showdate.show == s) ;  end
  def reserved_for_showdate?(sd) ;  reserved && (showdate == sd) ;  end

  def part_of_subscription?
    self.purchasemethod.shortdesc =~ /bundle/i
  end


  # operations on vouchers:
  #
  # reserve(showdate_id, logged_in)
  #  reservation binds it to a showdate and fills in who processed it
  # 
  def reserve(showdate, logged_in_customer)
    self.showdate = showdate
    self.processed_by_id = logged_in_customer.id
    self
  end

    

  def reserve_for(showdate_id, logged_in, comments='', opts={})
    ignore_cutoff = opts.has_key?(:ignore_cutoff) ? opts[:ignore_cutoff] : nil
    if self.unreserved?
      avail = ValidVoucher.numseats_for_showdate_by_vouchertype(showdate_id,self.customer,self.vouchertype, :redeeming => true, :ignore_cutoff => ignore_cutoff)
      if avail.available?
        self.showdate = Showdate.find(showdate_id)
        self.comments = comments.to_s || ''
        self.sold_on = Time.now
        self.save!
        a = Txn.add_audit_record(:txn_type => 'res_made',
                                 :customer_id => self.customer.id,
                                 :logged_in_id => logged_in,
                                 :show_id => self.showdate.show.id,
                                 :showdate_id => showdate_id,
                                 :voucher_id => self.id)
        return a
      else
        self.comments = avail.explanation
        return false
      end
    else                        # voucher already in use
      self.comments = "This ticket is already holding a reservation for
                        #{self.showdate.show.name} on
                        #{self.showdate.thedate.to_formatted_s(:showtime)}"
      return false
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
