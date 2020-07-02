class GenerateRefundItems < ActiveRecord::Migration
  def change
    Item.transaction do
      CanceledItem.finalized.each do |item|
        RefundedItem.from_cancellation(item).save!
      end
    end
  end
end
