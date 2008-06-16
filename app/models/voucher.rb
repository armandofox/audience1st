class Voucher < ActiveRecord::Base
  belongs_to :customer
  belongs_to :showdate
  belongs_to :vouchertype
  belongs_to :purchasemethod

  # every time a voucher is saved that belongs to a customer, that customer's
  # is_subscriber? attribute must be recomputed

  def compute_customer_is_subscriber
    return unless customer_id > 0
    begin
      if (c = Customer.find_by_id(customer_id)).kind_of?(Customer)
        old = c.is_current_subscriber
        new = c.role >= 0 &&
          c.vouchers.detect do |f|
          f.vouchertype && f.vouchertype.is_subscription? &&
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
            ((vouchertype.is_subscription ? "S" : "s") rescue "-"),
            ((vouchertype.is_bundle ? "B": "b") rescue "-"),
            ((vouchertype.offer_public ? "P" : "p") rescue "-"),
            external_key)
  end

  #validates_associated :customer, :vouchertype, :purchasemethod

  # return a voucher object that can be added to a shopping cart.
  # Fields like customer_id will be bound when voucher is actualy
  # purchased, and only then is it recorded permanently 

  def self.anonymous_voucher_for(showdate,vouchertype,promocode=nil,comment=nil)
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

  

  def self.add_vouchers_for_customer(vtype_id,howmany,cust,purchasemethod_id,showdate_id, comments, bywhom=Customer.generic_customer.id, fulfillment_needed=false,can_change=false)
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
                                       :customer_id => cust.id,
                                       :processed_by => bywhom,
                                       :changeable => can_change,
                                       :showdate_id => showdate_id)
      v.customer = cust
      v.save!
      cust.vouchers << v
      # if this voucher is actually a "bundle", recursively add the
      # bundled vouchers  
      # NOTE: fulfillment_needed is ALWAYS FALSE for vouchers included in a bundle!
      if v.vouchertype.is_bundle?
        can_change = v.vouchertype.is_subscription?
        purchasemethod_bundle_id = Purchasemethod.get_type_by_name('bundle')
        v.vouchertype.get_included_vouchers.each {  |type, qty|
          if (qty > 0)
            self.add_vouchers_for_customer(type, qty, cust,
                                           purchasemethod_bundle_id, showdate_id, '', bywhom, false, can_change)
          end
        }
      end
      v
    }
    return newvouchers
  end

  def add_to_customer(c)
    begin
      c.vouchers << self
      if self.vouchertype.is_bundle?
        purch_bundle = Purchasemethod.get_type_by_name('bundle')
        Voucher.transaction do
          self.vouchertype.get_included_vouchers.each do |type, qty|
            1.upto qty do
              c.vouchers <<
                Voucher.new_from_vouchertype(type,
                                             :processed_by => self.processed_by,
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

  def self.new_from_vouchertype(vt,args={})
    vt = Vouchertype.find(vt) unless vt.kind_of?(Vouchertype)
    Voucher.new({:vouchertype_id => vt.id,
                  :fulfillment_needed => vt.fulfillment_needed,
                  :sold_on => Time.now,
                  :valid_date => vt.valid_date,
                  :changeable => false,
                  :expiration_date => vt.expiration_date}.merge(args))
  end

  # return the "show" associated with a voucher.  If a regular voucher,
  # it's the show the voucher is associated with. If a bundle voucher,
  # it's the name of the bundle.
  def show ;  showdate.show ; end
  def show_or_bundle_name
    show.kind_of?(Show)  ? show.name :
      (vouchertype_id > 0 && vouchertype.is_bundle? ? vouchertype.name : "??")
  end

  def amount ; self.price ; end
  def price
    self.vouchertype.kind_of?(Vouchertype) ? self.vouchertype.price : 0.0
  end

  def account_code ; self.vouchertype.account_code ; end
  
  def is_bundle?
    self.vouchertype.kind_of?(Vouchertype) && self.vouchertype.is_bundle?
  end
  
  def reserved? ;   !self.showdate_id.to_i.zero? ;  end
  def unreserved? ; self.showdate_id.to_i.zero?  ;  end

  def date
    self.showdate_id.zero? ? nil : self.showdate.thedate
  end

  def valid_for_date?(dt)
    if (vd = self.valid_date)  && (ed = self.expiration_date)
      dt.between?(vd, ed)
    elsif vd && !ed
      dt >= vd
    elsif !vd && ed
      dt <= ed
    else
      true
    end
  end
  
  def validity_dates_as_string
    fmt = '%m/%d/%y'
    if (vd = self.valid_date) && (ed = self.expiration_date)
      "between #{vd.strftime(fmt)} and #{ed.strftime(fmt)}"
    elsif vd
      "after #{vd.strftime(fmt)}"
    elsif ed
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
    self.vouchertype.showdates.map { |sd| self.numseats_for_showdate(sd,:ignore_cutoff=>ignore_cutoff,:redeeming=>true) }
  end

  def redeemable_for_show?(show,ignore_cutoff = false)
    show = Show.find(show, :include => :showdates) unless show.kind_of?(Show)
    show.showdates.map { |sd| self.numseats_for_showdate(sd,:ignore_cutoff=>ignore_cutoff,:redeeming=>true) }.select { |av| av.howmany > 0 }
  end

  def not_already_used
    # Make sure voucher is not already in use.
    # Shouldn't happen using web interface.
    showdate_id.to_i == 0 
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
              (not_already_used ||
               (showdate.thedate > (Time.now - Option.value(:cancel_grace_period).minutes))))
    end
  end
    
  def reserved_for?(s)
    d = self.showdate_id.to_i
    if s.kind_of?(Show)
      s.showdates.map(&:id).include?(d)
    elsif s.kind_of?(Showdate)
      s.id == d
    elsif s.kind_of?(Fixnum)
      s == d
    else
      raise "Can't ask if voucher is reserved for a #{s.class}"
    end
  end

  def part_of_subscription?
    self.purchasemethod.shortdesc =~ /bundle/i
  end

  def reserve_for(showdate_id, logged_in, comments='', opts={})
    ignore_cutoff = opts.has_key?(:ignore_cutoff) ? opts[:ignore_cutoff] : nil
    if self.not_already_used
      avail = ValidVoucher.numseats_for_showdate_by_vouchertype(showdate_id,self.customer,self.vouchertype, :redeeming => true, :ignore_cutoff => ignore_cutoff)
      if avail.available?
        self.showdate = Showdate.find(showdate_id)
        self.comments = comments.to_s || ''
        self.processed_by = logged_in
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
    self.showdate = nil
    self.processed_by = logged_in
    if (self.save)
      save_showdate
    else
      nil
    end
  end

  def processed_by_name
    case
    when self.processed_by.to_i.zero?
      ""
    when c = Customer.find_by_id(self.processed_by)
      c.first_name
    else
      "???"
    end
  end
end
