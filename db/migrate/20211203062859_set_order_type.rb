class SetOrderType < ActiveRecord::Migration
  # some Orders got orphaned with no 'type' field when we introduced the
  # ImportedOrder subclass.  Set the "legacy" orders' type field to Order so they
  # can get harvested properly and/or be identified as regular Orders
  def change
    Order.where(:type => nil).update_all(:type => 'Order')
  end
end
