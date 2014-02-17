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
      @r = Store::BillingResponse.new(success=true, message="message", '0000')
    end
    it 'should be successful' do
      @r.should be_success
    end
    it 'should have txn id' do
      @r.authorization.should == '0000'
    end
  end
end
