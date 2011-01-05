class RemoveVoucherExpirationDate < ActiveRecord::Migration
  def self.up
    remove_column :vouchers, :expiration_date
  end

  def self.down
    add_column :vouchers, :expiration_date, :datetime, :null => false, :default => '2011-12-31'
  end
end
