class RemoveColumnFromOrders < ActiveRecord::Migration
  def change
    remove_column :comments
  end
end
