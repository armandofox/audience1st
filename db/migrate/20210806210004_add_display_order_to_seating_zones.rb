class AddDisplayOrderToSeatingZones < ActiveRecord::Migration
  def change
    change_table :seating_zones do |t|
      t.integer :display_order, :allow_nil => false, :default => 0
    end
  end
end
