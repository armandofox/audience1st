class Store
  
  def self.set_api_key
    Stripe.api_key = Option.stripe_secret
  end

  def self.pay_with_credit_card(order)
    self.set_api_key
    begin
      result = Stripe::Charge.create(
        :amount => (100 * order.total_price).to_i,
        :currency => 'usd',
        :card => order.purchase_args[:credit_card_token],
        :description => order.purchaser.inspect
        )
      order.update_attribute(:authorization, result.id)
    rescue Stripe::StripeError => e
      order.errors.add :base, "Credit card payment error: #{e.message}"
      nil
    end
  end

  def self.refund_credit_card(order, partial_amount=nil)
    self.set_api_key
    amount = ((partial_amount || order.total_price) * 100.0).to_i
    ch = Stripe::Charge.retrieve(order.authorization)
    refund = ch.refunds.create(:amount => amount)
  end
end
