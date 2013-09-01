class AddPurchaserIdToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :purchaser_id, :integer, :null => true, :default => nil
  end

  def self.down
  end
end
