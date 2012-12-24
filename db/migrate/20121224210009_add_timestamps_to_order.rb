class AddTimestampsToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :created_at, :datetime
    add_column :orders, :updated_at, :datetime
    connection.execute 'UPDATE orders SET updated_at=sold_on,created_at=sold_on WHERE updated_at IS NULL'
  end

  def self.down
  end
end
