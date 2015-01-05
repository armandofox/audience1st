class RemovePurchasemethodAndSoldOnFromItems < ActiveRecord::Migration
  def self.up
    remove_column :items, :sold_on
    remove_column :items, :purchasemethod_id
    remove_column :items, :updated_on # obsoleted by updated_at
  end

  def self.down
  end
end
