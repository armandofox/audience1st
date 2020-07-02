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
      break if items.empty?
      items.each do |i|
        i.update_attribute(:sold_on,
          (if i.kind_of?(CanceledItem) then i.updated_at else i.order.sold_on end))
      end
      print "."
    end
  end
end
