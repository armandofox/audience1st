require 'rails_helper'

describe Donation do
  describe 'creating from amount and account code' do
    before :each do
      @default = AccountCode.new
      allow(Donation).to receive(:default_code).and_return(@default)
    end
    it 'should use default when account code is nil' do
      expect(Donation.from_amount_and_account_code_id(15, nil).account_code).to eq(@default)
    end
  end
  describe "during walkup sale" do
    subject { Donation.walkup_donation(5.00) }
    its(:amount) { should == 5.00 }
    its(:account_code) { should be_a_kind_of AccountCode }
  end
end
