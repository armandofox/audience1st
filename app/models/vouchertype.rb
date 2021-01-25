class Vouchertype < ActiveRecord::Base
  
  belongs_to :account_code
  validates_associated :account_code

  has_many :valid_vouchers, :dependent => :destroy
  accepts_nested_attributes_for :valid_vouchers
  has_many :vouchers
  has_many :showdates, :through => :valid_vouchers
  serialize :included_vouchers, Hash

  NAME_LIMIT = 80
  CATEGORIES = %w(revenue comp subscriber bundle nonticket).freeze
  SINGLE_TICKET_CATEGORIES = %w(revenue comp).freeze
  
  validates_length_of :name, :within => 3..NAME_LIMIT, :message => "Voucher type name must be between 3 and #{NAME_LIMIT} characters"
  validates_uniqueness_of :name, :scope => :season
  validates_numericality_of :price, :greater_than => 0, :if => :revenue?
  validates_numericality_of :price
  validates_numericality_of :season, :in => 1900..2100
  #validates_presence_of(:account_code, :if => lambda { |v| v.price != 0 },
  #:message => "Vouchers that create revenue must have an account code")
  validates_inclusion_of :offer_public, :in => -1..2, :message => "Invalid specification of who may purchase"
  validates_inclusion_of :category, :in => CATEGORIES

  # Subscription vouchertypes shouldn't be available for walkup sale,
  # since we need to capture the address
  validate :subscriptions_shouldnt_be_walkups, :if => :subscription?

  # Bundles must include only zero-cost vouchers
  validate :bundles_include_only_zero_cost_vouchers, :if => :bundle?

  before_save :convert_bundle_quantities_to_ints
  before_update :cannot_change_category
  after_create :setup_valid_voucher_for_bundle, :if => :bundle?
  before_destroy :remove_deleted_vouchertype_from_bundle

  # Stackable scopes
  scope :for_season, ->(season) { where('season = ?', season) }
  scope :of_categories, ->(*cats)   { where('category IN (?)', cats.map(&:to_s)) }
  scope :except_categories, ->(*cats) { where('category NOT IN (?)', cats.map(&:to_s)) }
  scope :seat_vouchertypes, -> { where('category != ?', 'nonticket') }

  protected

  def remove_deleted_vouchertype_from_bundle
    return unless category == 'subscriber'
    id_s = self.id.to_s
    # delete from all bundles that contain it
    Vouchertype.transaction do
      Vouchertype.bundle_vouchertypes.each do |vt|
        vt.save! if vt.included_vouchers.delete(id_s)
      end
    end
  end

  # for bundle vouchers, the included_vouchers values should be ints
  # and the keys (id's) should be strings, eg {"3" => 1, "2" => 2} etc
  def convert_bundle_quantities_to_ints
    if included_vouchers
      included_vouchers.delete_if { |id,qty| qty.to_i.zero? }
      included_vouchers.transform_keys!(&:to_s)
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

  def subscriptions_shouldnt_be_walkups
    if walkup_sale_allowed?
      errors.add :base, "Subscription vouchers can't be sold via walkup sales screen, since address must be captured."
    end
  end
  
  # BUG clean up this method
  def bundles_include_only_zero_cost_vouchers
    included_vtypes = Vouchertype.find(included_vouchers.keys)
    non_free = included_vtypes.select { |v| v.price.to_i != 0 }
    unless non_free.empty?
      errors.add(:base, "Bundles cannot include revenue vouchers (#{non_free.map(&:name).join(', ')})")
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
                ["Sold by external reseller", EXTERNAL]].freeze

  public
  
  def inspect
    sprintf "[%d] %s, %s, $%.02f", (new_record? ? 0 : id), name, category, price
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

  def bundle?    ; category == 'bundle'         ; end
  def comp?      ; category == 'comp'           ; end
  def external?  ; offer_public == EXTERNAL     ; end
  def revenue?   ; category == 'revenue'        ; end
  def nonticket? ; category == 'nonticket'      ; end

  def reservable?
    !(['bundle','nonticket'].include?(category))
  end

  def zero_cost?
    price.zero?
  end
  
  def self_service_comp?
    category == 'comp' &&
      (offer_public == SUBSCRIBERS || offer_public == ANYONE)
  end

  def subscriber_voucher? ; category == 'subscriber' ; end

  def expiration_date ; Time.at_end_of_season(self.season) ; end

  def visibility
    @@offer_to.rassoc(self.offer_public).first rescue "Error (#{self.offer_public})"
  end

  scope :subscription_vouchertypes, -> {  where(:subscription => true) }
  scope :valid_now, -> {
    s,e = Time.season_boundaries(Time.this_season)
  }
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
  
  def valid_now?
    Time.current <= Time.at_end_of_season(self.season)
  end

  def valid_for_season?(which_season = Time.current.year)
    season == which_season
  end

  def num_included_vouchers
    included_vouchers.values.sum
  end

  # a monogamous vouchertype is valid for exactly one showdate.
  def unique_showdate
    showdates.length == 1 ? showdates.first : nil
  end

  # display methods

  def name_with_price ;  sprintf("%s - $%0.2f", name, price) ;  end

  def name_with_season ; "#{name} (#{Option.humanize_season(season)})" ; end

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
