class RecurringDonation < ActiveRecord::Base

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id

  belongs_to :customer
  has_many :donations

  validates :state, :inclusion => { :in => %w(preparing pending active stopped) }
  validates :amount, :numericality => { :only_integer => true, :greater_than => 0 }

  attr_reader :checkout_session # for stripe only, not persisted
  attr_reader :checkout_url # ditto

  def prepare_checkout
    # create the Price object and find/create the Product object for a recurring donation
    Store::Payment.set_api_key
    # TBD rescue exceptions
    @checkout_session = Stripe::Checkout::Session.create(
      {
        metadata: {  recurring_donation_id: self.id  },
        line_items: [
          {
            price_data: {
              currency: 'usd',
              unit_amount: self.amount * 100,
              recurring: { interval: 'month' },
              product_data: { name: "Monthly recurring donation to #{Option.venue}" }
            },
            quantity: 1
          }
        ],
        ui_mode: 'hosted',
        mode: 'subscription',
        customer_email: (self.customer.email if self.customer.valid_email_address?),
        success_url: Rails.application.routes.url_helpers.
          customer_recurring_donation_path(@customer, self),
        cancel_url: Rails.application.routes.url_helpers.
          customer_path(@customer)
      })
    @checkout_url = @checkout_session.url
  end

end
