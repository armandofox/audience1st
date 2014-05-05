class RemoveAccessibleSeatingMessage < ActiveRecord::Migration
  def self.up
    remove_column :options, :accessible_seating_notices
  end

  def self.down
    add_column :options, :accessible_seating_notices, :string, :null => false, :default => ''
  end
end
