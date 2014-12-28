class AddOrderIdToTxn < ActiveRecord::Migration
  def self.up
    change_table :txns do |t|
      t.references :order
    end
  end

  def self.down
    remove_column :txns, :order_id
  end
end
