class CreateRefundItems < ActiveRecord::Migration
  def change
    CanceledItem.where('amount > 0').each do |i|
      orig_updated_at = i.updated_at
      ref = RefundedItem.from_cancellation(i)
      ref.sold_on = i.updated_at
      ref.save!
      i.update_column(:updated_at, orig_updated_at)
    end
  end
end
