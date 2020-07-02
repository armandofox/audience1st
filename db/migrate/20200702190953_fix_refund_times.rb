class FixRefundTimes < ActiveRecord::Migration
  def change
    # for each RefundedItem
    #   find its corresponding CanceledItem
    #   set RefundedItem's sold_on to CanceledItem's sold_on
    #   set CanceledItem's sold_on to Order's sold_on
    count = 0
    Item.transaction do
      RefundedItem.all.each do |refund|
        canceled_item = refund.canceled_item
        refund.sold_on = canceled_item.sold_on
        canceled_item.sold_on = canceled_item.order.sold_on
        canceled_item.save!
        refund.save!
        count += 1
        print "." if (count % 100).zero?
      end
    end
  end
end
