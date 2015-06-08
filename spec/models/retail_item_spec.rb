require 'spec_helper'

describe RetailItem do
  before :each do
    @account1 = AccountCode.default_account_code
    @account2 = AccountCode.create!(:code => "1234", :name => "Fake")
  end
  describe 'new' do
    subject { RetailItem.from_amount_description_and_account_code_id(amount,description,id) }
    describe 'valid item' do
      let(:amount) { 1 }
      let(:description) { 'Item' }
      let(:id) { nil }
      it { should be_valid }
      its(:account_code_id) { should == @account1.id }
    end
    describe 'invalid amount' do
      let(:amount) { 0 }
      let(:description) { 'Item' }
      it { should_not be_valid }
      it { should have(1).error_on(:amount) }
    end
    describe 'blank description' do
      let(:amount) { 1 }
      let(:description) { nil }
      it { should_not be_valid }
      it { should have(1).error_on(:comments) }
    end
  end
  describe 'valid item' do
    subject { RetailItem.from_amount_description_and_account_code_id(3.51, 'Auction', @account2.id) }
    its(:account_code) { should == @account2 }
    its(:amount) { should == 3.51 }
    its(:one_line_description) { should match(/\$\s*3.51\s+Auction$/) }
  end
end
