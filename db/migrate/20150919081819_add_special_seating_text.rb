class AddSpecialSeatingText < ActiveRecord::Migration
  def self.up
    add_column :options, :special_seating_requests, :string, :null => false, :default => " Please describe (electric wheelchair, walker, cane, etc.)"
  end

  def self.down
  end
end
