class SingleShowVouchers < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :changeable, :boolean, :default => true
    add_column :vouchers, :fulfillment_needed, :boolean, :default => false
  end

  def self.down
    remove_column :vouchers, :changeable
    remove_column :vouchers, :fulfillment_needed
  end
end
