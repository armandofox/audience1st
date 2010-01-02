class Store
  include ActiveMerchant::Billing
  require 'money'
  
  private

  def self.pay_via_gateway(amount, cc, params)
    amount = Money.us_dollar((100 * amount).to_i)
    login = Option.value(:pgw_id)
    pwd = Option.value(:pgw_txn_key)
    gw = PAYMENT_GATEWAY.new(:login => login, :password => pwd)
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
