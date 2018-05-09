class Vouchertype < ActiveRecord::Base
  include VouchertypesHelper
  
  attr_accessible :category, :name, :price, :offer_public, :season, :display_order, :fulfillment_needed, :walkup_sale_allowed, :changeable, :subscription, :comments, :included_vouchers
  attr_accessible :account_code_id, :account_code

  belongs_to :account_code
  validates_associated :account_code

  has_many :valid_vouchers, :dependent => :destroy
  accepts_nested_attributes_for :valid_vouchers
  has_many :vouchers
  has_many :showdates, :through => :valid_vouchers
  serialize :included_vouchers, Hash

  NAME_LIMIT = 80
  CATEGORIES = %w(revenue comp subscriber bundle nonticket)
  
  validates_length_of :name, :within => 3..NAME_LIMIT, :message => "Voucher type name must be between 3 and #{NAME_LIMIT} characters"
  validates_numericality_of :price, :greater_than_or_equal_to => 0
  validates_numericality_of :season, :in => 1900..2100
  #validates_presence_of(:account_code, :if => lambda { |v| v.price != 0 },
  #:message => "Vouchers that create revenue must have an account code")
  validates_inclusion_of :offer_public, :in => -1..2, :message => "Invalid specification of who may purchase"
  validates_inclusion_of :category, :in => CATEGORIES
  # Vouchertypes whose price is zero must NOT be available
  # to subscribers or general public
  validates_exclusion_of(:offer_public, :in => [1,2],
                         :if => lambda { |v| v.price.to_i.zero? },
                         :message => "Zero-price vouchers can only be sold
                                        by box office or external reseller")

  # Subscription vouchertypes shouldn't be available for walkup sale,
  # since we need to capture the address
  validate :subscriptions_shouldnt_be_walkups, :if => :subscription?
  validate :restrict_if_free, :if => lambda { |v| v.price.to_i.zero? }
  # Bundles must include only zero-cost vouchers
  validate :bundles_include_only_zero_cost_vouchers, :if => :bundle?

  before_save :convert_bundle_quantities_to_ints
  before_update :cannot_change_category
  after_create :setup_valid_voucher_for_bundle, :if => :bundle?
  
  # Stackable scopes
  scope :for_season, ->(season) { where('season = ?', season) }
  scope :of_categories, ->(*cats)   { where('category IN (?)', cats.map(&:to_s)) }
  scope :except_categories, ->(*cats) { where('category NOT IN (?)', cats.map(&:to_s)) }

  protected

  # for bundle vouchers, the included_vouchers values should be ints
  def convert_bundle_quantities_to_ints
    if included_vouchers
      included_vouchers.delete_if { |id,qty| qty.to_i.zero? }
      included_vouchers.transform_values!(&:to_i) 
    end
  end

  # can't change the category of an existing bundle
  def cannot_change_category
    if category != category_was
      self.errors.add(:category, 'cannot be changed on an existing voucher type')
      false
    end
  end
  # When a bundle is created, automatically create the single valid-voucher
  # that will be linked to it.
  def setup_valid_voucher_for_bundle
    self.valid_vouchers.create!(
      :max_sales_for_type => nil, # unlimited
      :start_sales => Time.at_beginning_of_season(season),
      :end_sales   => Time.at_end_of_season(season),
      :promo_code  => nil
      )
  end

  def self.ensure_valid_name(name)
    # make name valid if it isn't already
    name = name.to_s
    name += '___' if name.length < 3
    name[0,NAME_LIMIT]
  end
  
  def subscriptions_shouldnt_be_walkups
    if walkup_sale_allowed?
      errors.add :base, "Subscription vouchers can't be sold via walkup sales screen, since address must be captured."
    end
  end
  
  def restrict_if_free
    if offer_public == ANYONE
      errors.add :base, "Free vouchers can't be available to public"
    elsif category == :subscription
      errors.add :base, "Free vouchers can't qualify recipient as Subscriber"
    end
  end

  # BUG clean up this method
  def bundles_include_only_zero_cost_vouchers
    return if self.get_included_vouchers.empty?
    self.get_included_vouchers.each_pair do |id,num|
      next if num.to_i.zero?
      unless v = Vouchertype.find_by_id(id)
        errors.add :base,"Vouchertype #{id} doesn't exist"
      else
        unless v.price.to_i.zero?
          errors.add :base,"Bundle can't include revenue voucher #{id} (#{v.name})"
        end
      end
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

  public
  
  def inspect
    sprintf "[%d] %s, %s, $%.02f", id, name, category, price
  end

  def <=>(other)
    ord = (display_order <=> other.display_order)
    ord == 0 ? price <=> other.price : ord
  end
  
  def offer_public_as_string
    case offer_public
    when BOXOFFICE then "Box office only"
    when SUBSCRIBERS then "Subscribers"
    when ANYONE then "Anyone"
    when EXTERNAL then "External Resellers"
    else "Unknown (#{offer_public})"
    end
  end

  def self.offer_to
    @@offer_to
  end

  def visible_to?(customer)
    case offer_public
    when ANYONE then true
    when SUBSCRIBERS then customer.subscriber?
    else false
    end
  end

  def bundle? ; category == 'bundle' ; end
  def comp? ; category == 'comp' ; end
  def external? ; offer_public == EXTERNAL ; end

  def subscriber_voucher? ; category == 'subscriber' ; end

  def expiration_date ; Time.at_end_of_season(self.season) ; end

  def visibility
    @@offer_to.rassoc(self.offer_public).first rescue "Error (#{self.offer_public})"
  end

  def self.comp_vouchertypes(season=nil)
    vtypes =  season ? for_season(season) : self
    vtypes.of_categories('comp').order('created_at')
  end

  def self.nonbundle_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.except_categories('bundle').
      order('season DESC,display_order,created_at')
  end

  def self.bundle_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.of_categories('bundle').order('season DESC,display_order,created_at')
  end

  def self.subscription_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.of_categories('bundle').where('subscription = ?', true).
      order('season DESC,display_order,created_at')
  end

  def self.revenue_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.of_categories('revenue').order('season DESC,display_order,created_at')
  end

  def self.subscriber_vouchertypes_in_bundles(season=nil)
    vtypes = season ? for_season(season) : self
    # bug: should really check for vouchertypes that are components of
    #  a bundle that is a subscription, but this is hard to do since
    #  the included_vouchers property is serialized as a hash
    vtypes.of_categories('subscriber').order('season DESC,display_order,created_at')
  end

  def self.nonticket_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.of_categories('nonticket').order('season DESC,display_order,created_at')
  end

  def self.zero_cost_vouchertypes(season=nil)
    vtypes = season ? for_season(season) : self
    vtypes.where('price = ?', 0).order('season DESC,display_order,created_at')
  end

  def numseats_for_showdate(showdate)
    if (vv = self.valid_vouchers.detect { |v| v.showdate_id == showdate.id })
      vv.seats_remaining
    else
      0
    end
  end
  
  def valid_as_of?(date)
    date.to_time <= Time.now.at_end_of_season(self.season)
  end

  def valid_now?
    valid_as_of?(Time.now)
  end

  def valid_for_season?(which_season = Time.now.year)
    season == which_season
  end

  def self.create_external_voucher_for_season!(name,price,year=Time.now.year)
    name = Vouchertype.ensure_valid_name(name)
    return Vouchertype.create!(:name => name,
      :price => price,
      :offer_public => Vouchertype::EXTERNAL,
      :category => (price.to_i.zero? ? 'comp' : 'revenue'),
      :subscription => false,
      :season => year)
  end

  # BUG can we delete this method??
  def get_included_vouchers
    if self.bundle?
      (self.included_vouchers ||= {}).
        delete_if { |k,v| v.blank? }.
        inject(Hash.new) { |h,(k,v)| h[k.to_i] = v.to_i ; h }
    else
      {}
    end
  end

  def num_included_vouchers
    get_included_vouchers.values.sum
  end

  def instantiate(howmany, args = {})
    all_vouchers = []
    howmany.times do
      voucher = Voucher.new_from_vouchertype(self, args)
      all_vouchers << voucher
      if self.bundle?
        included_vouchers = []
        self.get_included_vouchers.each_pair do |vtype,qty|
          included_vouchers += Vouchertype.find(vtype).instantiate(qty)
        end
        voucher.bundled_vouchers += included_vouchers
        all_vouchers += included_vouchers
      end
    end
    all_vouchers
  end

  # a monogamous vouchertype is valid for exactly one showdate.
  def unique_showdate
    showdates.length == 1 ? showdates.first : nil
  end

  # display methods

  def name_with_price ;  sprintf("%s - $%0.2f", name, price) ;  end

  def name_with_season ; "#{name} (#{humanize_season(season)})" ; end

  def name_with_season_and_price; sprintf("%s - $%0.2f", name_with_season, price) ; end

  def self.walkup_vouchertypes
    Vouchertype.where('subscription = ? AND walkup_sale_allowed = ?', false, true)
  end
  
  # Override content_columns to not display included vouchers (since
  # requires special code)

  def self.content_columns
    c = super
    c.delete_if { |x| x.name.match('included_vouchers') }
    c
  end

  # BUG: this duplicates functionality 
  
end

# For convenience, we define using_promo_code as an instance method of Enumerable so that
# we can write subs = ValidVoucher.bundles_available_to(...).using_promo_code('foo')

module Enumerable
  def using_promo_code(p = '')
    p = p.to_s.strip
    self.select { |vt| p.contained_in_or_blank(vt.bundle_promo_code) }
  end
end
