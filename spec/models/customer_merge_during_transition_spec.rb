require 'rails_helper'

# This is to test the merging during the grace period(the transition period between SHA-1 to Identity),
# which includes multiple possibilities.
describe Customer, "merging during transition period" do
  def merge(c0, c1)
    c0.merge_automatically!(c1)
  end
  describe "merge between two old users" do
    before(:each) do
      @user_keep = create(:old_customer)
      @user_merged = create(:old_customer)
      @user_keep.save!
      @user_merged.save!
      allow(@user_merged).to receive(:fresher_than?).and_return(true)
      allow(Customer).to receive(:update_foreign_keys_from_to).and_return(['Wat, Wat'])
    end
    it "should use the old way to store the password" do
      merge(@user_keep, @user_merged)
      expect(Authorization.find_by_provider_and_customer_id('Identity', @user_keep.id)).to be_nil
    end

    it "should change the older user's password to the fresher user's password" do
      merge(@user_keep, @user_merged)
      expect(Customer.find(@user_keep.id).crypted_password).to eq @user_merged.crypted_password
    end
  end

  describe "merge new user to old users" do
    before(:each) do
      @user_keep = create(:old_customer)
      @user_merged = create(:customer)
      @user_keep.save!
      @user_merged.save!
      allow(@user_merged).to receive(:fresher_than?).and_return(true)
      allow(Customer).to receive(:update_foreign_keys_from_to).and_return(['Wat, Wat'])
    end
    it "should create a anthentification through the new way" do
      pass = Authorization.find_by_provider_and_customer_id('Identity', @user_merged.id).password_digest
      merge(@user_keep, @user_merged)
      expect(Authorization.find_by_provider_and_customer_id('Identity', @user_keep.id).password_digest).to eq(pass)
    end

    # For the following test, it's a matter of migration strategy, so just leave it alone for now.

    # it "should keep the email and password of the old user from the customers table" do
    #   merge(@user_keep, @user_merged)
    #   expect(Customer.find(@user_keep.id).email).must_be_empty
    #   expect(Customer.find(@user_keep.id).crypted_password).to must_be_empty
    # end
  end

  describe "merge old user to new user" do
    before(:each) do
      @user_keep = create(:customer)
      @user_merged = create(:old_customer)
      @user_keep.save!
      @user_merged.save!
      allow(@user_merged).to receive(:fresher_than?).and_return(true)
      allow(Customer).to receive(:update_foreign_keys_from_to).and_return(['Wat, Wat'])
    end
    it "should keep the current password" do
      pass = Authorization.find_by_provider_and_customer_id('Identity', @user_keep.id).password_digest
      merge(@user_keep, @user_merged)
      expect(Authorization.find_by_provider_and_customer_id('Identity', @user_keep.id).password_digest).to eq(pass)
    end
  end
end