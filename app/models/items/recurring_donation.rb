class RecurringDonation < Item

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id

  belongs_to :customer
  has_many :donations

  validates :state, :inclusion => { :in => %w(preparing pending active stopped) }, :allow_blank => true
  validates :amount, :numericality => { :only_integer => true, :greater_than => 0 }

  attr_reader :checkout_session # for stripe only, not persisted
  attr_reader :checkout_url # ditto

  def prepare_checkout(callback_host)
    helpers = Rails.application.routes.url_helpers
    success_url = URI.join(callback_host,
                           helpers.customer_recurring_donations_path(self.customer, self))
    cancel_url = URI.join(callback_host,
                          helpers.customer_path(self.customer))
    
    # how the recurring donation description will appear in Stripe dashboard
    recurring_donation_stripe_name = "$#{amount.to_i} monthly #{customer.full_name_with_email}"

    # create the Price object and find/create the Product object for a recurring donation
    Store::Payment.set_api_key
    # TBD rescue exceptions
    @checkout_session = Stripe::Checkout::Session.create(
      {
        metadata: {  recurring_donation_primary_key: self.id  },
        line_items: [
          {
            price_data: {
              currency: 'usd',
              unit_amount: (self.amount * 100).to_i,
              recurring: { interval: 'month' },
              product_data: { name: recurring_donation_stripe_name }
            },
            quantity: 1
          }
        ],
        ui_mode: 'hosted',
        mode: 'subscription',
        customer_email: (self.customer.email if self.customer.valid_email_address?),
        success_url: success_url,
        cancel_url: cancel_url
      })
    @checkout_url = @checkout_session.url
  end

end
