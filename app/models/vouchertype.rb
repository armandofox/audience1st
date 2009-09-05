class Vouchertype < ActiveRecord::Base
  has_many :valid_vouchers
  has_many :vouchers, :dependent => :nullify
  has_many :showdates, :through => :valid_vouchers
  serialize :included_vouchers, Hash

  validates_length_of :name, :within => 3..40, :message => "Voucher type name must be between 3 and 40 characters"
  validates_numericality_of :price
  validates_inclusion_of :offer_public, :in => -1..2, :message => "Invalid specification of who may purchase"

  # Vouchertypes whose price is zero must NOT be available
  # to subscribers or general public
  validates_exclusion_of :offer_public, :in => [1,2], :if => lambda { |v| v.price.zero? }, :message => "Zero-price vouchers must not be accessible to subscribers or regular patrons"

  # Subscription vouchertypes shouldn't be available for walkup sale,
  # since we need to capture the address
  validate :subscriptions_shouldnt_be_walkups

  def subscriptions_shouldnt_be_walkups
    if walkup_sale_allowed && is_subscription
      errors.add_to_base "Subscription vouchers can't be sold via walkup sales screen, since address must be captured."
    end
  end
  

  # Functions that determine visibility of a voucher type to particular
  # customers
  BOXOFFICE = 0
  SUBSCRIBERS = 1
  ANYONE = 2
  EXTERNAL = -1

  @@offer_to = [["Box office use only", BOXOFFICE],
                ["Subscribers may purchase",SUBSCRIBERS],
                ["Anyone may purchase", ANYONE],
                ["Sold by external reseller", EXTERNAL]]

  def self.offer_to
    @@offer_to
  end

  def is_bundle?
    self.class.to_s == 'BundleVouchertype'
  end

  def visibility
    @@offer_to.rassoc(self.offer_public).first rescue "Error (#{self.offer_public})"
  end

  def self.find_products(args={})
    restrict = []
    arglist = []
    case args[:for_purchase_by]
    when :subscribers
      restrict << "(offer_public = #{SUBSCRIBERS} OR offer_public = #{ANYONE})"
    when :boxoffice
      restrict << "offer_public = #{BOXOFFICE}"
    when :external
      restrict << "offer_public = #{EXTERNAL}"
    else
      restrict << "offer_public = #{ANYONE}"
    end
    if (created_on = args[:since])
      restrict << "created_on >= ?"
      arglist << created_on
    end
    case args[:type]
    when :bundled_voucher
      restrict << "type != 'BundleVouchertype' AND is_subscription = 0"
      restrict << "#{Time.db.now} BETWEEN valid_date AND expiration_date" unless
        (args[:for_purchase_by] == :boxoffice || args[:ignore_cutoff])
    when :subscription
      restrict << "type = 'BundleVouchertype' AND is_subscription = 1"
      restrict << "#{Time.db_now} BETWEEN bundle_sales_start AND bundle_sales_end" unless
        (args[:for_purchase_by] == :boxoffice || args[:ignore_cutoff])
    when :bundle
      restrict << "type = 'BundleVouchertype'"
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
