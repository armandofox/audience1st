class RecurringDonation < ActiveRecord::Base

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id

  belongs_to :customer
  has_many :donations

  validates :stripe_price_oid, :presence => true
  validates :state, :inclusion => { :in => %w(building pending active stopped) }
  validates :amount, :numericality => { :only_integer => true, :greater_than => 0 }

  STRIPE_PRODUCT_ATTRIBS = {
    active: true,
    name: "Monthly recurring donation to #{Option.venue}",
    description: "Monthly recurring donation to #{Option.venue}"
  }

  def self.find_or_create_default_product!
    Store::Payment.set_api_key
    # TBD rescue exceptions around API calls
    products =  Stripe::Product.list({limit: 1})
    if products['data'].size == 1
      products['data'][0]
    else
      Stripe::Product.create(STRIPE_PRODUCT_ATTRIBS)
    end
  end

end
