class Store

  def self.card_not_present_purchase(amount, cc, bill_to, order_num)
    raise "Invalid purchaser" unless bill_to.valid_as_purchaser?
    raise "Zero transaction amount" if amount.zero?
    params = {
      :order_id => order_num,
      :email => bill_to.possibly_synthetic_email,
      :billing_address =>  {
        :name => bill_to.full_name,
        :address1 => bill_to.street,
        :city => bill_to.city,
        :state => bill_to.state,
        :zip => bill_to.zip,
        :phone => bill_to.possibly_synthetic_phone,
        :country => 'US'
      }
    }
    amount = Money.us_dollar((100 * amount).to_i)
    gw = PAYMENT_GATEWAY.new(:login => Option.value(:pgw_id),
                             :password => Option.value(:pgw_txn_key))
    begin
      purch = gw.purchase(amount, cc, params)
    rescue Exception => e
      purch = ActiveMerchant::Billing::Response.new(success=false,
                                                    message = e.message)
    end
    purch
  end

end
