class PurchasemethodsEtc < ActiveRecord::Migration
  def self.up
    add_column :purchasemethods, :nonrevenue, :boolean, :default => false
    [2,8].each { |i| Purchasemethod.find(i).update_attribute :nonrevenue, true }
    add_column :vouchers, :bundle_id, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :purchasemethods, :nonrevenue
    remove_column :vouchers, :bundle_id
  end
end
