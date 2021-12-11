class DefaultOrderType < ActiveRecord::Migration
  def change
    change_column :orders, :type, :string, :null => false, :default => 'Order'
    Order.where(:type => nil).update_all(:type => 'Order')
  end
end
