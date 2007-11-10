require File.dirname(__FILE__) + '/../test_helper'
require "yaml"

TOMS_CC = '%B4242424242424242^FOOLERY/TOM ^0912101113441100000000735000000?;4242424242424242=091210111344735?'

class StoreTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  require 'money.rb'
  
  def setup
    settings = YAML::load(ERB.new((IO.read("#{RAILS_ROOT}/config/settings.yml"))).result).symbolize_keys
    buyers = YAML::load(ERB.new((IO.read(File.dirname(__FILE__)+'/../fixtures/buyers.yml'))).result).symbolize_keys
    Base.gateway_mode = :test
    pp = settings[:authorized_net_test_account].symbolize_keys
    @toms_cc = CreditCard.new(buyers[:toms_credit_card].symbolize_keys)
    @toms_params = buyers[:toms_order_info].symbolize_keys
    @toms_params[:address] = buyers[:toms_address].symbolize_keys
    @gateway = AuthorizedNetGateway.new(:login => pp[:username],
                            :password => pp[:password],
                            :subject => '')
  end
  
  # Replace this with your real tests.
  def test_010_successful_purchase
    response = @gateway.purchase(Money.new(100), @toms_cc, @toms_params)
    assert response.success?
    assert response.test?
    assert_equal '(TESTMODE) This transaction has been approved', response.message
    assert response.authorization
  end

  def test_011_failed_purchase
    @toms_cc.number= '999999999999'
    response = @gateway.purchase(Money.new(100), @toms_cc, @toms_params)
    assert !response.success?
  end

end
