class AddWalkupToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :walkup, :boolean, :default => false
    add_index :orders, ['walkup'], :name => 'index_orders_on_walkup'
  end

  def self.down
    remove_column :orders, :walkup
  end
end
