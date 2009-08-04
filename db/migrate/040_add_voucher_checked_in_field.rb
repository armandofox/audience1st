class AddVoucherCheckedInField < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :used, :datetime, :null => true, :default => nil
  end

  def self.down
    remove_column :vouchers, :used
  end
end
