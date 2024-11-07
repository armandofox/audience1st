class RecurringDonation < Item

  has_many :donations, :foreign_key => :recurring_donation_id

  belongs_to :customer
  belongs_to :account_code

  attr_accessor :payment_intent

  validates_associated :account_code
  validates_presence_of :account_code_id

  validates :state, :inclusion => { :in => %w(preparing pending active stopped) }, :allow_blank => true
  validates :amount, :numericality => { :greater_than => 0 }

  def first_donation
    Donation.where(recurring_donation_id: id).order(sold_on: :asc).first
  end

  def monthly_amount
    donation = first_donation
    donation ? donation.amount : nil 
  end

  def total_amount_received
    Donation.where(recurring_donation_id: id).sum(:amount)
  end

  # Create payment intent on stripe side; record any errors
  def create_payment_intent
    return nil unless self.valid? # requires amount, account code, start state
    Store::Payment.set_api_key
    params = {
      payment_method_types: ['card'],
      amount: (self.amount * 100).to_i,
      currency: 'usd'
    }
    begin
      self.payment_intent = Stripe::PaymentIntent.create(params)
    rescue Stripe::StripeError => e
      self.errors.add(:base, "Stripe: #{e.error.message}")
    end
    self
  end

  def prepare_checkout(callback_host)
    helpers = Rails.application.routes.url_helpers
    success_url = URI.join(callback_host,
                           helpers.stripe_callback_recurring_donation_success_path(self))
    cancel_url = URI.join(callback_host,
                          helpers.stripe_callback_recurring_donation_failure_path(self))
    
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

  def one_line_description(opts={})
    if opts[:suppress_price]
      "Recurring Donation to #{account_code.name}"
    else
      sprintf("$%6.2f Recurring Donation to %s ($%6.2f received in total)", monthly_amount, account_code.name, total_amount_received)
    end
  end

  def description_for_audit_txn
    sprintf("%.2f %s recurring donation [%d]", monthly_amount, account_code.name, id)
  end


end
