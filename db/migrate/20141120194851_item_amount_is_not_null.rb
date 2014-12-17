class ItemAmountIsNotNull < ActiveRecord::Migration
  def self.up
    change_column :items, :amount, :float, :default => 0
  end

  def self.down
    change_column :items, :amount, :float, :null => true, :default => nil
  end
end
