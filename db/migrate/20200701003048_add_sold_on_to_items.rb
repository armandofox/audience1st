class AddSoldOnToItems < ActiveRecord::Migration
  def change
    add_column :items, :sold_on, :datetime
    Item.reset_column_information
    # Set the sold_on date for CanceledItems to the date of cancellation (= item.updated_at)
    # Set the sold_on date for all other item types to the order's sold_on
    # Item.transaction do  # not enough dyno memory to allow luxury of this safeguard...
    offset = 0
    while (1)
      items =  Item.finalized.offset(offset).limit(1000)
      offset += 1000
      refunds_created = 0
      break if items.empty?
      items.each do |i|
        case i
        when CanceledItem
          i.account_code_id ||= i.vouchertype.account_code_id if i.amount != 0
          i.sold_on = i.order.sold_on
          cancel_time = i.updated_at
          # create the Refund transaction
          ref = RefundedItem.from_cancellation(i)
          ref.sold_on = cancel_time
          ref.save!
          i.save!
          i.update_attribute(:updated_at, cancel_time)
          refunds_created += 1
          break
        when RefundedItem
          # do nothing
          break
        else
          orig_updated_at = i.updated_at
          i.sold_on = i.order.sold_on
          i.save!
          i.update_attribute(:updated_at, orig_updated_at)
        end
      end
      print "."
    end
    puts "\n#{refunds_created} refund items created"
  end
end
