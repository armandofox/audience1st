class CreateOrdersFromItemGroups < ActiveRecord::Migration
  def self.up
    Item.update_all 'updated_at = updated_on' # nondestructively "add" updated_at column (exists but ignored)
    Item.reset_column_information
    add_column :orders, :ship_to_purchaser, :boolean, :default => true
    # All Vouchers should 'inherit' as their amount the price attribute from Vouchertype
    ActiveRecord::Base.connection.execute """
UPDATE items,vouchertypes
   SET items.amount=vouchertypes.price
 WHERE items.vouchertype_id=vouchertypes.id
   AND items.type='Voucher'
"""
    # A group of Items should be grouped into an Order when all of the following are true:
    #  - order_id is null or zero (ie this is a 'legacy' voucher and not already part of an order)
    #  - following fields all have same value:
    all_vouchers = Item.all
    voucher_groups = all_vouchers.group_by { |i| [i.gift_purchaser_id, i.ship_to_purchaser, i.processed_by_id, i.purchasemethod_id, i.sold_on, i.walkup] }
    # result is an ordered hash
    say_with_time "Creating #{voucher_groups.length} orders from #{all_vouchers.length} items" do
      voucher_groups.each_value do |result|
        begin
          new_order = Order.create_from_existing_vouchers! result
          new_create_time = result.map(&:created_at).min || Time.now
          new_update_time = result.map(&:updated_at).max || new_create_time
          new_order.update_attributes!(:created_at => new_create_time,
            :updated_at => new_update_time)
        rescue Exception => e
          say "[#{result.map(&:id).join(',')}]: #{e.inspect}"
        end
      end
    end
  end

  def self.down
  end
end
