class OfferPublic < ActiveRecord::Migration
  def self.up
    change_column :vouchertypes, :offer_public, :integer, :default => 0, :null => false
    remove_column :valid_vouchers, :offer_public
    Vouchertype.reset_column_information
    Vouchertype.update_all "offer_public = 2", "offer_public = 1"
    Vouchertype.update_all "offer_public = 1", "name LIKE '%guest%'"
    Vouchertype.update_all "offer_public = -1", "name LIKE '%goldstar%'"
    add_column :donations, :letter_sent, :datetime, :null => true, :default => nil
  end

  def self.down
    remove_column :donations, :letter_sent
    Vouchertype.update_all "offer_public = 1" , "offer_public > 0"
    Vouchertype.update_all "offer_public = 0" , "offer_public < 0"
    change_column :vouchertypes, :offer_public, :boolean, :default => false
    add_column :valid_vouchers, :offer_public, :boolean, :default => false
  end
end
