class AddShipToRecipientToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :ship_to_purchaser, :boolean, :default => true
  end

  def self.down
    remove_column :items, :ship_to_purchaser
  end
end
