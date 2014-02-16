require 'spec_helper'

describe Store::BillingResponse do
  describe 'when failed' do
    before :each do
      @r = Store::BillingResponse.new(false, 'Failed')
    end
    it 'should not be successful' do
      @r.should_not be_success
    end
  end
  describe 'success' do
    before :each do
      @r = Store::BillingResponse.new(success=true, message="message", :transaction_id => "0000")
    end
    it 'should be successful' do
      @r.should be_success
    end
  end
end
