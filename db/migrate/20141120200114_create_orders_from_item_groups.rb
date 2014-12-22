# what about subscriptions where order_id is set on subscription voucher but not components?
# why isn't order_id actually getting set during migration - was it because each subclass of Item needs to belong_to Order (rather than just Item itself)?

class CreateOrdersFromItemGroups < ActiveRecord::Migration
  def ddl_transaction(&block)
    say "Migrating without transaction..."
    block.call
  end
  def self.up
    Item.update_all 'updated_at = updated_on' # nondestructively "add" updated_at column (exists but ignored)
    Item.reset_column_information
    add_column :orders, :ship_to_purchaser, :boolean, :default => true
    # All Vouchers should 'inherit' as their amount the price attribute from Vouchertype
    say_with_time "Setting price on loose items" do
      Item.connection.execute """
UPDATE items,vouchertypes
   SET items.amount=vouchertypes.price
 WHERE items.vouchertype_id=vouchertypes.id
   AND items.type='Voucher'
"""
    end
    say_with_time "Setting order IDs on bundle vouchers" do
      Item.connection.execute """
UPDATE items i1, items i2
   SET i1.order_id = i2.order_id
 WHERE i1.bundle_id = i2.id AND i1.order_id IS NULL
"""
    end
    # A group of Items should be grouped into an Order when all of the following are true:
    #  - order_id is null or zero (ie this is a 'legacy' voucher and not already part of an order)
    #  - following fields all have same value:
    total_count = Item.count(:all, :conditions => 'order_id IS NULL')
    items_done = 0
    limit = 5000
    while true
      GC.start                  # force garbage collection to keep mem leaks under control
      items = Item.find(:all, :conditions => "order_id IS NULL", :limit => limit)
      break if items.empty?
      groups = items.group_by { |i| [i.gift_purchaser_id, i.ship_to_purchaser, i.processed_by_id, i.purchasemethod_id, i.sold_on, i.walkup] }
      # result is an ordered hash
      say_with_time "Creating #{groups.length} orders from items #{items_done+1}..#{items_done+items.length} of #{total_count} (first id is #{items.first.id})" do
        groups.each_value do |result|
          begin
            new_order = Order.create_from_existing_items! result
            new_create_time = result.map(&:created_at).min || Time.now
            new_update_time = result.map(&:updated_at).max || new_create_time
            new_order.update_attributes!(:created_at => new_create_time,
              :updated_at => new_update_time)
          rescue Exception => e
            say "[#{result.map(&:id).join(',')}]: #{e.inspect}"
          end
        end
      end
      items_done += items.length
    end
    # This migration seems to screw up session state bigtime, so....
    say "Nuking session table"
    Session.delete_all
  end

  def self.down
  end
end
