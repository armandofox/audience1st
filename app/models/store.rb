class Store
  class BillingResponse
    attr_reader :success, :message, :args
    def success? ; @success ;  end
    def initialize(success, message, args1={}, args2={})
      @success = success
      @message = message
      @args1 = args1
      @args2 = args2
    end
  end
  require 'stripe'
  
  def self.purchase!(method, amount, params={}, &blk)
    return Store::BillingResponse.new(false, "Null payment type") unless (method && params)
    blk = Proc.new {} unless block_given?
    case method.to_sym
    when :credit_card
      raise "Zero transaction amount" if amount.zero?
      self.purchase_with_credit_card!(amount, params, blk)
    when :check
      self.purchase_with_check!(amount, params[:check_number], blk)
    when :cash
      self.purchase_with_cash!(amount, blk)
    else
      Store::BillingResponse.new(false,
        "Invalid payment type #{method}")
    end
  end

  private
  
  def self.description_from_params(params)
    [params[:order_number],
      params[:bill_to].full_name,
      params[:bill_to].day_phone,
      params[:bill_to].email,
      params[:comment]].compact.join(' ')
  end
  
  def self.purchase_with_credit_card!(orig_amount, params, proc)
    if params[:credit_card_token].blank?
      return Store::BillingResponse.new(false,
        'Credit card information could not be read from form submission', {})
    end
    description = description_from_params(params)
    amount = (100 * orig_amount.to_f).to_i
    Stripe.api_key = Option.stripe_secret_key
    begin
      ActiveRecord::Base.transaction do
        proc.call
        result = Stripe::Charge.create(
          :amount => amount,
          :currency => 'usd',
          :card => params[:credit_card_token],
          :description => description)
        return Store::BillingResponse.new(true,
            'Credit card successfully charged',
            {},
            {:authorization => result.id})
      end
    rescue Stripe::StripeError => e
      return Store::BillingResponse.new(false,
        'Payment gateway error: ' + e.message,
        {} )
    rescue Exception => e
      return  Store::BillingResponse.new(false, e.message)
    end
  end

  def self.purchase_with_cash!(amount, proc)
    ActiveRecord::Base.transaction do
      begin
        proc.call
        Store::BillingResponse.new(success=true,
                                              message="Cash purchase recorded",
                                              :transaction_id => "CASH")
      rescue Exception => e
        Store::BillingResponse.new(success=false,
          message=e.message)
      end
    end
  end

  def self.purchase_with_check!(amount, cknum, proc)
    ActiveRecord::Base.transaction do
      begin
        proc.call
        Store::BillingResponse.new(success = true,
                                            message = "Check recorded",
                                            :transaction_id => cknum.to_s)
      rescue Exception => e
        Store::BillingResponse.new(success = false,
                                              message = e.message)
      end
    end
  end    
end
