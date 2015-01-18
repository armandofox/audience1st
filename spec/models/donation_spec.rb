require 'spec_helper'

describe Donation do
  describe "default account code" do
    before(:each) do
      Option.stub!(:default_donation_account_code).and_return '9999'
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
  end
  describe 'creating from amount and account code' do
    before :each do
      @default = AccountCode.new
      Donation.stub!(:default_code).and_return(@default)
    end
    it 'should use default when account code is nil' do
      Donation.from_amount_and_account_code_id(15, nil).account_code.should == @default
    end
  end
  describe "during walkup sale" do
    subject { Donation.walkup_donation(5.00) }
    its(:amount) { should == 5.00 }
    its(:account_code) { should be_a_kind_of AccountCode }
  end
end
