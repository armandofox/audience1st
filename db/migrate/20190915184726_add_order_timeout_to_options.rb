class AddOrderTimeoutToOptions < ActiveRecord::Migration
  def change
    change_table :options do |t|
      t.integer :order_timeout, :null => false, :default => 5
    end
  end
end
