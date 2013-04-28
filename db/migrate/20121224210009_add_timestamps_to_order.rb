class AddTimestampsToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :valid_vouchers, :text
    add_column :orders, :donation_data, :text
    add_column :orders, :comments, :string, :null => true
    add_column :orders, :created_at, :datetime, :null => true
    add_column :orders, :updated_at, :datetime, :null => true
    connection.execute 'UPDATE orders SET updated_at=sold_on,created_at=sold_on WHERE updated_at IS NULL'
  end

  def self.down
  end
end
