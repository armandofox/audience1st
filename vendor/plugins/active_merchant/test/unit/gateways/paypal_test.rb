require File.dirname(__FILE__) + '/../../test_helper'

class PaypalTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
 
  def setup
    @gateway = PaypalGateway.new(
                :login => 'cody', 
                :password => 'test',
                :pem => ''
               )

    @address = { :address1 => '1234 My Street',
                 :address2 => 'Apt 1',
                 :company => 'Widgets Inc',
                 :city => 'Ottawa',
                 :state => 'ON',
                 :zip => 'K1C2N6',
                 :country => 'Canada',
                 :phone => '(555)555-5555'
               }

    @creditcard = CreditCard.new({
      :number => '4242424242424242',
      :month => 8,
      :year => 2006,
      :first_name => 'Longbob',
      :last_name => 'Longsen'
    })

    Base.gateway_mode = :test
  end 
  
  def teardown
    Base.gateway_mode = :test
  end 

  def test_no_ip_address
    assert_raise(ArgumentError){ @gateway.purchase(Money.ca_dollar(100), @creditcard, :address => @address)}
  end

  def test_purchase_success    
    @creditcard.number = 1

    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :address => @address, :ip => '127.0.0.1')
    assert_equal Response, response.class
    assert_equal '#0001', response.params['receiptid']
    assert_equal true, response.success?
  end

  def test_purchase_error
    @creditcard.number = 2

    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :order_id => 1, :address => @address, :ip => '127.0.0.1')
    assert_equal Response, response.class
    assert_equal '#0001', response.params['receiptid']
    assert_equal false, response.success?

  end
  
  def test_purchase_exceptions
    @creditcard.number = 3 
    
    assert_raise(Error) do
      assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :order_id => 1, :address => @address, :ip => '127.0.0.1')   
    end
  end
  
  def test_amount_style
   assert_equal '10.34', @gateway.send(:amount, Money.new(1034))
   assert_equal '10.34', @gateway.send(:amount, 1034)
                                                      
   assert_raise(ArgumentError) do
     @gateway.send(:amount, '10.34')
   end
  end
  
  def test_live_redirect_url
    Base.gateway_mode = :production
    assert_equal 'https://www.paypal.com/cgibin/webscr?cmd=_express-checkout&token=1234567890', PaypalGateway.redirect_url_for('1234567890')
  end
  
  def test_test_redirect_url
    assert_equal 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=1234567890', PaypalGateway.redirect_url_for('1234567890')
  end
end
