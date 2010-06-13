=begin rdoc
A ValidVoucher is a record indicating the conditions under which a particular
voucher type can be redeemed.  For non-subscriptions, the valid voucher refers
to a particular showdate ID.  For subscriptions, the showdate ID is zero.
#
is a record that states "for a particular showdate ID, this particular type of voucher
is accepted", and encodes additional information such as the capacity limit for this vouchertype for thsi
 performance, the start and end dates of redemption for this vouchertype, etc.
=end

class ValidVoucher < ActiveRecord::Base
  # A valid_voucher must be associated with exactly 1 showdate and 1 vouchertype
  belongs_to :showdate
  belongs_to :vouchertype
  validates_associated :showdate, :if => lambda { |v| !(v.vouchertype.bundle?) }
  validates_associated :vouchertype
  validates_numericality_of :max_sales_for_type

  validate :check_expiration_dates

  require 'set'

  # for a given showdate ID, a particular vouchertype ID should be listed only once.
  validates_uniqueness_of :vouchertype_id, :scope => :showdate_id, :message => "already valid for this performance"

  # explanation when no seats are available
  cattr_accessor :no_seats_explanation

  private

  # Vouchertype's valid date must not be later than valid_voucher start date
  # Vouchertype expiration date must not be earlier than valid_voucher end date
  def check_expiration_dates
    if start_sales.blank? || end_sales.blank?
      errors.add_to_base "Dates and times for start and end sales must be provided"
      return
    end
    vt = self.vouchertype
    if start_sales < vt.valid_date
      errors.add_to_base "Voucher type '#{vt.name}' isn't valid before
        #{vt.valid_date.to_formatted_s(:short)}, but you've indicated
        sales should start earlier (#{self.start_sales.to_formatted_s(:short)})"
    end
    if self.end_sales > vt.expiration_date
      errors.add_to_base "Voucher type '#{vt.name}' expires on
        #{vt.expiration_date.to_formatted_s(:short)}, but you've indicated
        sales should continue until #{self.end_sales.to_formatted_s(:short)})"
    end
  end
  
  public

  def visible_to(cust)
    Vouchertype.find(self.vouchertype_id).visible_to(cust)
  end

  def to_s
    sprintf "%s max %3d %s- %s %s", vouchertype, max_sales_for_type,
    start_sales.strftime('%c'), end_sales.strftime('%c'),
    password
  end
  
  def printable_name ;  self.showdate.printable_name ;  end
  def vouchertype_name ; self.vouchertype.name ; end
  def price ; self.vouchertype.price ; end

  def self.for_advance_sales(passwords = [])
    general_conds = "? BETWEEN start_sales AND end_sales"
    general_opts = [Time.now]
    password_conds = "password IS NULL OR password = ''"
    password_opts = []
    unless passwords.empty?
      password_conds += " OR password LIKE ? " * passwords.length
    end
    v = ValidVoucher.find(:all,
                          :conditions => ["#{general_conds} AND (#{password_conds})", general_opts + passwords])
    v.to_set.classify( &:showdate_id )
  end

  def seats_remaining
    nseatsleft = self.showdate.saleable_seats_left
    if max_sales_for_type.zero?
      # no limits on this type, so limit is just how many seats are left
      return nseatsleft
    else
      # limits on type: sales limit is the lesser of the number of seats
      # left or the number of seats left of this type
    [nseatsleft, [0,max_sales_for_type-showdate.sales_by_type(vouchertype_id)].max].min
    end
  end

  # is this valid-voucher redeemable by a Box Office agent?
  def self.advance_sale_seats_for(showdate,customer,password='')
    @@no_seats_explanation = ''
    if customer.is_boxoffice
      vv = showdate.valid_vouchers.find(:all, :joins => :vouchertype,
        :conditions => ['vouchertypes.category IN (?)', [:revenue,:nonticket]])
      # no date checks or anything like that.  Number available for each
      # seat is based on actual house capacity (vs. max sales).
      return vv.map do |v|
        av = AvailableSeat.new(showdate,customer,v.vouchertype,
          showdate.total_seats_left)
      end
    end
    # not boxoffice.  Subscribers vs nonsubscribers differ only as
    # far as the vouchertype availability.  If the show itself is not
    # available for advance sales, we're done.
    unless Time.now < showdate.end_advance_sales
      @@no_seats_explanation = 'Advance sales for performance have ended'
      return []
    end
    avail_to = (customer.is_subscriber? ?
      [Vouchertype::SUBSCRIBERS,Vouchertype::ANYONE] :
      [Vouchertype::ANYONE])
    # make sure advance sales start/end are respected, as well
    # as vouchertype
    conds = <<EOCONDS1
        (vouchertypes.category IN (?))
        AND (vouchertypes.offer_public IN (?))
        AND (? BETWEEN start_sales AND end_sales)
EOCONDS1
    bind_variables =  [[:revenue,:nonticket], avail_to, Time.now]
    if !password.blank?
      conds << " AND (LOWER(promo_code) IN (?))"
      bind_variables << password.downcase.split(',').unshift('')
    end
    vv = showdate.valid_vouchers.find(:all, :joins => :vouchertype,
      :conditions => [conds, *bind_variables])
    if vv.empty?
      @@no_seats_explanation = "No seats matching criteria: #{ValidVoucher.sanitize_sql([conds,*bind_variables])}.  Available types:\n" << showdate.valid_vouchers.map(&:to_s).join("\n")
      return []
    end
    # remove those for which the max number of seats available
    # (if specified) has already been reached in current sales
    av = vv.map do |v|
      a = AvailableSeat.new(showdate,customer,v.vouchertype,v.seats_left)
    end
    av
  end

  def seats_left
    saleable_seats_left = showdate.saleable_seats_left
    if (max_sales_for_type.zero? || saleable_seats_left.zero?)
      # num seats left is just however many are left for show
      saleable_seats_left
    else
      # num seats may be inventory constrained. Result is the LEAST
      # of available seats left, or available seats for THIS TYPE.
      inventory_left_for_type = [(max_sales_for_type - showdate.sales_by_type(self.vouchertype_id)), 0].max
      [inventory_left_for_type, saleable_seats_left].min
    end
  end
        

  # get number of seats available for a showdate, given a customer
  # (different customers have different purchasing rights), a list of
  # passwords (some voucher types are password protected), and whether
  # to ignore time-based sales cutoffs (default: false).
  # Returns an AvailableSeat object encapsulating the result of htis
  # computation along with an English explanation if appropriate.

  def self.numseats_for_showdate_by_vouchertype(sd,cust,vtype,opts={})
    av = AvailableSeat.new(sd,cust,vtype,0) # fail safe: 0 available
    ignore_cutoff = opts.has_key?(:ignore_cutoff) ? opts[:ignore_cutoff] : cust.is_boxoffice
    redeeming = opts.has_key?(:redeeming) ? opts[:redeeming] : false
    # Basic checks: is show sold out? have advance sales ended?
    sd = Showdate.find(sd) unless (sd.kind_of?(Showdate))
    if (res = sold_out_or_date_invalid(sd,ignore_cutoff))
      av.howmany = 0
      av.explanation = res
      av.staff_only = true
      return av
    end
    # Find the valid_vouchers, if any, that make this vouchertype eligible
    vtype = Vouchertype.find(vtype, :include => :valid_vouchers) unless
      vtype.kind_of?(Vouchertype)
    unless redeeming
      return av unless  check_visible_to(av,ignore_cutoff)
    end
    #vv = vtype.valid_vouchers.find_all_by_showdate_id(sd.id)
    vv  = vtype.valid_vouchers.select do |v|
      v.showdate_id == sd.id &&
        v.password_matches(opts[:promo_code])
    end
    if vv.empty?
      av.howmany = 0
      av.explanation = "Ticket type not valid for this performance"
      return av
    end
    if vv.length != 1
      raise "#{vv.length} entries for vouchertype #{vtype.id} and showdate #{sd.id} (should be 1)"
    end
    av.staff_only = false
    av.howmany,av.explanation = check_date_and_quantity(vv.first,ignore_cutoff)
    av
  end

  def self.numseats_for_showdate(sd,cust,opts={})
    sd = Showdate.find(sd) unless (sd.kind_of?(Showdate))
    sd.vouchertypes.map { |v| numseats_for_showdate_by_vouchertype(sd,cust,v,opts) }
     # BUG: retrieve passwords from opts
     # BUG: need to consider somewhere whether voucher is expired
  end

  # instantiate(logged_in_customer, purchasemethod, howmany=1)
  #  n vouchers of given vouchertype and for given showdate are created
  #  voucher is bound to customer
  # returns the list of newly-instantiated vouchers
  def instantiate(logged_in_customer, purchasemethod, howmany=1)
    Array.new(howmany) do |i|
      self.new_voucher(purchasemethod).reserve(self.showdate,
                                               logged_in_customer)
    end
  end

  def new_voucher(purchasemethod = Purchasemethod.default)
    return Voucher.new_from_vouchertype(self.vouchertype,
                                        :purchasemethod => purchasemethod)
  end

  def password_matches(str)
    str ||= ''
    return true if self.password.blank?
    return (self.password.upcase.split(/\s*,\s*/).include?(str.strip.upcase))
  end

  private

  # return true if this valid_voucher should be displayed based on password.
  # that is, if it has no associated promo code, OR if the supplied string
  # matches one of the associated promo codes.
  
  def self.check_visible_to(av, admin=false)
    cust = av.customer
    av.staff_only = true        # only staff can see reason for reject
    case av.vouchertype.offer_public
    when -1                     # external reseller
      av.explanation = "Sold by external reseller only"
      return false
    when 0                      # box office use only
      av.explanation = "Not for customer purchase"
      return (admin && av.vouchertype.price.to_f > 0.0) # don't show comps.
    when 1                      # subscribers only
      av.explanation = "Subscribers only"
      av.staff_only = false     # ok to show this to customer
      return cust.subscriber?
    when 2
      return true
    else
      raise "Unknown value #{av.vouchertype.offer_public} for offer_public"
    end
  end


  def self.sold_out_or_date_invalid(sd,ignore_cutoff)
    now = Time.now
    if sd.saleable_seats_left < 1
      "Performance is sold out"
    elsif  sd.thedate < now && !ignore_cutoff
      "Performance date has already passed"
    elsif sd.end_advance_sales < now && !ignore_cutoff
      "Advance reservations for this performance are closed"
    else
      nil
    end
  end

  def self.check_date_and_quantity(v,ignore_cutoff)
    if (howmany = v.seats_remaining).zero?
      [0, "None left"]
    elsif (!ignore_cutoff)
      # check date-related constraints
      if v.end_sales && v.end_sales < Time.now
        [0, "Advance sales for this ticket type have ended"]
      elsif v.start_sales && v.start_sales > Time.now
        [0, "Tickets go on sale #{v.start_sales.to_formatted_s(:month_day_only)}"]
      else
        [howmany, "available"]
      end
    else                      # ignore date constraints
      [howmany, "available"]
    end
  end

end
