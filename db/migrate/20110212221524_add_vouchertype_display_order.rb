class AddVouchertypeDisplayOrder < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :display_order, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :vouchertypes, :display_order
  end
end
