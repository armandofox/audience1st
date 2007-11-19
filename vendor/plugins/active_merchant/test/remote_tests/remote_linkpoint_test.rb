#
# In order for this test to pass, a valid store number and PEM file 
# are required. Unfortunately, with LinkPoint YOU CAN'T JUST USE ANY 
# OLD STORE NUMBER. Also, you can't just generate your own PEM file. 
# You'll need to use a special PEM file provided by LinkPoint. 
#
# Go to http://www.linkpoint.com/support/sup_teststore.asp to set up 
# a test account and obtain your PEM file. 
#

require 'test/unit'
require File.dirname(__FILE__) + '/../test_helper'

ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/../mycert.pem'  )



class LinkpointTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def setup
    ActiveMerchant::Billing::Base.gateway_mode = :test
    
    @gateway = LinkpointGateway.new(:login => 1909444802, :result => "GOOD")

    @creditcard = CreditCard.new({
      :number => '4111111111111111',
      :month => Time.now.month.to_s,
      :year => (Time.now + 1.year).year,
      :first_name => 'Captain',
      :last_name => 'Jack',
    })
  end
  
  def test_remote_authorize
    assert response = @gateway.authorize(Money.us_dollar(2400), @creditcard, :order_id => 1000, 
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_capture
    assert response = @gateway.capture(Money.us_dollar(2400), @creditcard, :order_id => 1000,
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_purchase
    assert response = @gateway.purchase(Money.us_dollar(2400), @creditcard, :order_id => 1001,
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_credit
    assert response = @gateway.credit(Money.us_dollar(2400), @creditcard, :order_id => 1001,
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end

  
  def test_remote_recurring
    assert response = @gateway.recurring(Money.us_dollar(2400), @creditcard, :order_id => 1003, :installments => 12, :startdate => "immediate", :periodicity => :monthly,
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  
  def test_remote_decline
    @gateway = LinkpointGateway.new(:login => 1909444802, :result => "DECLINE")
    assert response = @gateway.purchase(Money.us_dollar(100), @creditcard, :order_id => 1002,
      :address => {
        :address1 => '1313 lucky lane',
        :city => 'Lost Angeles',
        :state => 'CA',
        :zip => '90210'
      }
    )
    assert_equal Response, response.class
    assert_equal false, response.success?
    assert_equal "DECLINED", response.params["r_approved"]
  end
end
