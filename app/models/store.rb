class Store
  include ActiveMerchant::Billing
  
  private

  def self.pay_via_gateway(amount, cc, params)
    amount = Money.us_dollar((100 * amount).to_i)
    login = Option.value(:pgw_id)
    pwd = Option.value(:pgw_txn_key)
    gw = PAYMENT_GATEWAY.new(:login => login, :password => password)
    return gw.purchase(amount,cc,params)
  end

  public
  
  def self.purchase!(method, amount, params={}, &blk)
    return ActiveMerchant::Billing::Response.new(false, "Null payment type") unless (method && params)
    blk = Proc.new {} unless block_given?
    case method.to_sym
    when :credit_card
      raise "Zero transaction amount" if amount.zero?
      self.purchase_with_credit_card!(amount, params[:credit_card],
                                      params[:bill_to], params[:order_number],
                                      blk)
    when :check
      self.purchase_with_check!(amount, params[:check_number], blk)
    when :cash
      self.purchase_with_cash!(amount, blk)
    else
      ActiveMerchant::Billing::Response.new(false,
        "Invalid payment type #{method}")
    end
  end

  private
  
  def self.purchase_with_credit_card!(amount, cc, bill_to, order_num, proc)
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
    purch = nil
    begin
      ActiveRecord::Base.transaction do
        proc.call
        # here if block didn't raise error
        purch = Store.pay_via_gateway(amount, cc, params)
        raise purch.message unless purch.success?
      end
    rescue Exception => e
      message = purch.nil? ? e.message :
        case purch.message
        when /ECONNRESET/
          "Payment gateway not responding. Please try again in a few seconds."
        when /decline/i
          "Charge declined. Please contact your credit card issuer for assistance."
        else
          purch.message
        end
      purch = ActiveMerchant::Billing::Response.new(false, message)
    end
    return purch
  end

  def self.purchase_with_cash!(amount, proc)
    ActiveRecord::Base.transaction do
      begin
        proc.call
        ActiveMerchant::Billing::Response.new(success=true,
                                              message="Cash purchase recorded",
                                              :transaction_id => "CASH")
      rescue Exception => e
        ActiveMerchant::Billing::Response.new(success=false,
                                              message=e.message)
      end
    end
  end

  def self.purchase_with_check!(amount, cknum, proc)
    ActiveRecord::Base.transaction do
      begin
        proc.call
        ActiveMerchant::Billing::Response.new(success = true,
                                            message = "Check recorded",
                                            :transaction_id => cknum.to_s)
      rescue Exception => e
        ActiveMerchant::Billing::Response.new(success = false,
                                              message = e.message)
      end
    end
  end    
end
