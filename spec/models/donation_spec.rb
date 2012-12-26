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
  describe "online donations" do
    before(:each) do
      @admin = BasicModels.create_generic_customer(:role => 100)
      @cust = BasicModels.create_generic_customer
    end  
    describe "during self-purchase" do
      it "should be valid" do
        @donation = Donation.online_donation(5.00, nil, @cust.id, @cust.id)
        @donation.should be_valid
      end
    end
    describe "during admin purchase" do
      it "should be valid" do
        @donation = Donation.online_donation(5.00, nil, @cust.id, @admin.id)
        @donation.should be_valid
      end
    end
    describe "during walkup sale" do
      it "should be assigned default account code" do
        Option.stub!(:value).with(:default_donation_account_code).and_return('4444')
        @donation = Donation.walkup_donation(5.00, @admin.id)
        @donation.account_code.code.should == '4444'
      end
    end
  end
end
