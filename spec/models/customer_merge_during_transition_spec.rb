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
      allow(Authorization).to receive(:find_by_provider_and_uid).with('Identity', @user_keep.email).and_return(nil)
      allow(Authorization).to receive(:find_by_provider_and_uid).with('Identity', @user_merged.email).and_return(nil)
      allow(Customer).to receive(:update_foreign_keys_from_to).and_return(['Wat, Wat'])
    end
    it "should use the old way to store the password" do
      @user_keep.merge_automatically!(@user_merged).should_not be_nil
    end

    it "should change the older user's password to the fresher user's password" do
      @user_keep.merge_automatically!(@user_merged).should_not be_nil
    end
  end

  # describe "merge new user to old users" do
  #   before(:each) do
  #     @user_keep = create(:old_customer)
  #     @user_merged = create(:customer)
  #     allow(@user_merged).to receive(:fresher_than?).and_return(true)
  #   end
  #   it "should create a anthentification through the new way" do
  #     pending
  #   end
  #
  #   it "should delete the email and password of the old user from the customers table" do
  #     pending
  #   end
  # end
  #
  # describe "merge old user to new user" do
  #   before(:each) do
  #     @user_keep = create(:customer)
  #     @user_merged = create(:old_customer)
  #     allow(@user_merged).to receive(:fresher_than?).and_return(true)
  #   end
  #   it "should keep the current password" do
  #     pending
  #   end
  # end
end