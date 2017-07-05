require 'rails_helper'

describe RetailItem do
  before :each do
    @account1 = AccountCode.create!(:code => "5678", :name => "Default")
    @account2 = AccountCode.create!(:code => "1234", :name => "Fake")
    Option.first.update_attributes!(:default_retail_account_code => @account1.id)
  end
  describe 'new' do
    it 'gets default account code' do
      @i = RetailItem.from_amount_description_and_account_code_id(1,'Item',nil)
      expect(@i).to be_valid
      expect(@i.account_code_id).to eq(@account1.id)
    end
    it 'rejects invalid amount' do
      @i = RetailItem.from_amount_description_and_account_code_id(0,'Item',nil)
      expect(@i).not_to be_valid
      expect(@i.errors[:amount].size).to eq(1)
    end
    it 'rejects blank description' do
      @i = RetailItem.from_amount_description_and_account_code_id(1,nil,nil)
      expect(@i).not_to be_valid
      expect(@i.errors[:comments].size).to eq(1)
    end
  end
  it 'gets correct attributes when valid' do
    @i = RetailItem.from_amount_description_and_account_code_id(3.51, 'Auction', @account2.id)
    expect(@i.account_code).to eq(@account2)
    expect(@i.amount).to eq(3.51)
    expect(@i.one_line_description).to match(/\$\s*3.51\s+Auction$/)
  end
end
