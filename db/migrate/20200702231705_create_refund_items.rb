class CreateRefundItems < ActiveRecord::Migration
  def change
    cxl = CanceledItem.where('amount > 0')
    puts "Creating #{cxl.count} refund items"
    count = 0
    cxl.each do |i|
      orig_updated_at = i.updated_at
      ref = RefundedItem.from_cancellation(i)
      ref.sold_on = i.updated_at
      ref.save!
      i.update_column(:updated_at, orig_updated_at)
      count += 1
      print "." if count % 100 == 0
    end
  end
end
