class Store

  public
  
  def self.purchase!(amount, params={}, &blk)
    case params[:method]
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
      raise "Invalid payment type #{how}"
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
    amount = Money.us_dollar((100 * amount).to_i)
    gw = PAYMENT_GATEWAY.new(:login => Option.value(:pgw_id),
                             :password => Option.value(:pgw_txn_key))
    ActiveRecord::Base.transaction do
      begin
        proc.call
        purch = gw.purchase(amount, cc, params)
        unless purch.success?
          # raise error, to cause DB rollback of txn
          case purch.message
          when /ECONNRESET/
            raise "Payment gateway not responding. Please wait a few seconds and try again."
          when /decline/i
            raise "Charge was declined. Please contact your credit card issuer for assistance."
          else
            raise purch.message
          end
        end
      rescue Exception => e
        purch = ActiveMerchant::Billing::Response.new(success=false,
                                                      message = e.message)
      end
    end
    purch
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
