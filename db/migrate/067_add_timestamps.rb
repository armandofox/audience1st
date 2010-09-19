class AddTimestamps < ActiveRecord::Migration
  def self.up
    %w(valid_vouchers showdates shows options).each do |tbl|
      add_column tbl, :created_at, :datetime, :null => false, :default => Time.now
      add_column tbl, :updated_at, :datetime, :null => false, :default => 1.month.ago
    end
  end

  def self.down
    %w(valid_vouchers showdates shows options).each do |tbl|
      remove_column tbl, :created_at
      remove_column tbl, :updated_at
    end
  end
end
