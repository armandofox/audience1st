class AddOrdersController < ActiveRecord::Migration
  def self.up
    create_table :orders, :force => true do |t|
      t.string :authorization, :null => true, :default => nil
      t.integer :customer_id
      t.integer :purchasemethod_id
      t.integer :processed_by_id
      t.datetime :sold_on
    end
    add_index :orders, ['authorization'], :name => 'index_orders_on_authorization'
    add_column :items, :order_id, :integer
    add_index :items, ['order_id'], :name => 'index_items_on_order_id'
  end

  def self.down
  end
end
