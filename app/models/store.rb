class Store
  include ActiveMerchant::Billing
  require 'money'
  require 'stripe'
  
  private

  def self.pay_via_gateway(amount, token, params)
    if token.blank?
      return ActiveMerchant::Billing::Response.new(false,
        'Credit card information could not be read from form submission', {})
    end
    amount = 100 * amount.to_i
    Stripe.api_key = Option.value(:stripe_secret_key)
    # use Stripe's description field to make charges searchable by name or email
    description =
      [params[:order_id], params[:billing_address][:name], params[:email], params[:comment]].join(' ')
    begin
      result = Stripe::Charge.create(
        :amount => amount,
        :currency => 'usd',
        :card => token,
        :description => description)
      return ActiveMerchant::Billing::Response.new(true,
        'Credit card successfully charged',
        {:transaction_id => result.id})
    rescue Stripe::StripeError => e
      return ActiveMerchant::Billing::Response.new(false,
        'Payment gateway error: ' + e.message,
        {} )
    end
  end

  public
  
  def self.purchase!(method, amount, params={}, &blk)
    return ActiveMerchant::Billing::Response.new(false, "Null payment type") unless (method && params)
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
      ActiveMerchant::Billing::Response.new(false,
        "Invalid payment type #{method}")
    end
  end

  def self.process_swipe_data(s)
    s = s.chomp
    # trk1: '%B' accnum '^' last '/' first '^' YYMM svccode(3 chr)
    #   discretionary data (up to 8 chr)  '?'
    # '%B' is a format code for the standard credit card "open" format; format
    # code '%A' would indicate a proprietary encoding
    trk1 = Regexp.new('^%B(\d{1,19})\\^([^/]+)/?([^/]+)?\\^(\d\d)(\d\d)[^?]+\\?', :ignore_case => true)
    # trk2: ';' accnum '=' YY MM svccode(3 chr) discretionary(up to 8 chr) '?'
    trk2 = Regexp.new(';(\d{1,19})=(\d\d)(\d\d).{3,12}\?', :ignore_case => true)

    # if card has a track 1, we use that (even if trk 2 also present)
    # else if only has a track 2, try to use that, but doesn't include name
    # else error.

    if s.match(trk1)
      RAILS_DEFAULT_LOGGER.info "Matched track 1"
      accnum = Regexp.last_match(1).to_s
      lastname = Regexp.last_match(2).to_s.upcase
      firstname = Regexp.last_match(3).to_s.upcase # may be nil if this field was absent
      expyear = 2000 + Regexp.last_match(4).to_i
      expmonth = Regexp.last_match(5).to_i
    elsif s.match(trk2)
      RAILS_DEFAULT_LOGGER.info "Matched track 2"
      accnum = Regexp.last_match(1).to_s
      expyear = 2000 + Regexp.last_match(2).to_i
      expmonth = Regexp.last_match(3).to_i
      lastname = firstname = ''
    else
      RAILS_DEFAULT_LOGGER.info "No match on track 1 or 2"
      accnum = expyear = expmonth = lastname = firstname = ''
    end
    return CreditCard.new(:first_name => firstname.strip,
                   :last_name => lastname.strip,
                   :month => expmonth.to_i,
                   :year => expyear.to_i,
                   :number => accnum.strip)
  end


  private
  
  def self.purchase_with_credit_card!(amount, params, proc)
    description = [
      params[:order_number],
      params[:bill_to].full_name,
      params[:bill_to].day_phone,
      params[:bill_to].email,
      params[:comment]].compact.join(' ')
    purch = nil
    begin
      ActiveRecord::Base.transaction do
        proc.call
        # here if block didn't raise error
        amount = 100 * amount.to_i
        Stripe.api_key = Option.value(:stripe_secret_key)
        result = Stripe::Charge.create(
          :amount => amount,
          :currency => 'usd',
          :card => params[:credit_card_token],
          :description => description)
        return ActiveMerchant::Billing::Response.new(true,
            'Credit card successfully charged',
            {:transaction_id => result.id})
      end
    rescue Stripe::StripeError => e
      return ActiveMerchant::Billing::Response.new(false,
        'Payment gateway error: ' + e.message,
        {} )
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
      return  ActiveMerchant::Billing::Response.new(false, message)
    end
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
