class Checkin < ActiveRecord::Migration
  def self.up
    rename_column 'vouchers', 'used', 'checked_in'
  end

  def self.down
    rename_column 'vouchers', 'checked_in', 'used'
  end
end
