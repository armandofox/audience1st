require 'spec_helper'

describe Donation do
  describe "default account code" do
    before(:each) do
      Option.stub!(:value).with(:default_donation_account_code).and_return '9999'
      AccountCode.delete_all
    end
    it "should find default account code if it exists" do
      a = AccountCode.create!(:name => "Gen", :code => '9999')
      Donation.default_code.should == a
    end
    it "should find any matching account code if multiple match" do
      a = AccountCode.create!(:name => "New acct", :code => "9999")
      b = AccountCode.create!(:name => "New acct 2", :code => "9999")
      [a,b].should include(Donation.default_code)
    end
    it "should create new account code if specified code doesn't exist" do
      AccountCode.find_by_code('9999').should be_nil
      d = Donation.default_code
      Donation.default_code.code.should == '9999'
      AccountCode.find_by_code('9999').should_not be_nil
    end
  end
  describe 'creating from amount and account code' do
    before :each do
      @default = AccountCode.new
      Donation.stub!(:default_code).and_return(@default)
    end
    it 'should use default when account code is nil' do
      Donation.from_amount_and_account_code(15, nil).account_code.should == @default
    end
    it 'should use default when account code not found'
    it 'should use account code when matches existing' 
  end
  describe "during walkup sale" do
    it "should be assigned default account code" do ; flunk ; end
  end
end
