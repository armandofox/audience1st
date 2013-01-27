class Store
  require 'stripe'
  
  def self.pay_with_credit_card(order)
    Stripe.api_key = Option.stripe_secret_key
    begin
      result = Stripe::Charge.create(
        :amount => (100 * order.total_price).to_i,
        :currency => 'usd',
        :card => order.purchase_args[:credit_card_token],
        :description => order.purchaser.inspect
        )
      order.authorization = result.id
    rescue Stripe::StripeError => e
      order.errors.add_to_base "Credit card payment error: #{e.message}"
      nil
    end
  end

end
