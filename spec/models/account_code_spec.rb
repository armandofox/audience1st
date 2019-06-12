require 'rails_helper'

describe AccountCode do
  describe "deleting last one" do
    before :each do
      AccountCode.first.destroy while AccountCode.count > 1 
      @a = AccountCode.first
    end
    it 'includes error message' do
      @a.destroy
      expect(@a.errors[:base]).to include('at least one account code must exist')
    end
    it 'does not do the deletion' do
      expect { @a.destroy }.to_not change { AccountCode.count }
    end
  end
  describe "deleting a default account code" do
    before :each do
      @a = create(:account_code)
      Option.first.update_attributes!(:default_donation_account_code => @a.code)
    end
    it 'includes error message' do
      @a.destroy
      expect(@a.errors[:base]).to include("it's the default donation account code")
    end
    it 'does not delete' do
      expect { @a.destroy }.to_not change { AccountCode.count }
    end
  end
  it 'deletes an account code otherwise' do
    create(:account_code)
    a = create(:account_code)
    expect { a.destroy }.to change { AccountCode.count }.by(-1)
  end
end
