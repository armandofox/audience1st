class Vouchertype < ActiveRecord::Base
  has_many :valid_vouchers
  has_many :vouchers, :dependent => :destroy
  has_many :showdates, :through => :valid_vouchers
  serialize :included_vouchers, Hash

  validates_length_of :name, :within => 3..40, :message => "Voucher type name must be between 3 and 40 characters"
  validates_numericality_of :price
  validates_inclusion_of :offer_public, :in => -1..2, :message => "Invalid specification of who may purchase"

  # Functions that determine visibility of a voucher type to particular
  # customers

  @@offer_to = [["Box office use only", 0],
                ["Subscribers may purchase",1],
                ["Anyone may purchase", 2],
                ["Sold by external reseller", -1]]

  def self.offer_to
    @@offer_to
  end

  def visibility
    @@offer_to.rassoc(self.offer_public).first rescue "Error (#{self.offer_public})"
  end

  def self.find_products(args={})
    restrict = []
    arglist = []
    case args[:for_purchase_by]
    when :subscribers
      restrict << "(offer_public = 1 OR offer_public = 2)"
    when :boxoffice
      restrict << "offer_public = 0"
    when :external
      restrict << "offer_public = -1"
    else
      restrict << "offer_public = 2"
    end
    if (created_on = args[:since])
      restrict << "created_on >= ?"
      arglist << created_on
    end
    case args[:type]
    when :bundled_voucher
      restrict << "is_bundle = 0 AND is_subscription = 0"
      restrict << "#{Time.db.now} BETWEEN valid_date AND expiration_date" unless
        (args[:for_purchase_by] == :boxoffice || args[:ignore_cutoff])
    when :subscription
      restrict << "is_bundle = 1 AND is_subscription = 1"
      restrict << "#{Time.db_now} BETWEEN bundle_sales_start AND bundle_sales_end" unless
        (args[:for_purchase_by] == :boxoffice || args[:ignore_cutoff])
    when :bundle
      restrict << "is_bundle = 1"
      restrict << "#{Time.db_now} BETWEEN bundle_sales_start AND bundle_sales_end" unless
        (args[:for_purchase_by] == :boxoffice || args[:ignore_cutoff])
    end
    if args.has_key?(:walkup)
      case args[:walkup]
      when true
        restrict << "walkup_sale_allowed = 1"
      when false
        restrict << "walkup_sale_allowed = 0"
      end
    end
    arglist.unshift(restrict.join(" AND "))
    Vouchertype.find(:all, :conditions => arglist)
  end

  def valid_as_of?(date)
    d = date.to_time
    d >= valid_date && d <= expiration_date
  end

  def valid_now?
    valid_as_of?(Time.now)
  end

  def get_included_vouchers
    if self.is_bundle?
      hsh = self.included_vouchers
      numeric_hsh = Hash.new
      # convert everthing to ints (stored as strings)
      hsh.each_pair { |k,v| numeric_hsh[k.to_i || 0] = (v.to_i || 0) }
      numeric_hsh
    else
      {}
    end
  end

  def name_with_price
    self.name + sprintf(" - $%0.2f", self.price)
  end

  # Override content_columns to not display included vouchers (since
  # requires special code)

  def self.content_columns
    c = super
    c.delete_if { |x| x.name.match('included_vouchers') }
    c
  end

end
