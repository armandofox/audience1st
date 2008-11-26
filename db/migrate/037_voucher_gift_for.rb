class VoucherGiftFor < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :gift_purchaser_id, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :vouchers, :gift_purchaser_id
  end
end
