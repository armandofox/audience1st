class GenerateRefundItems < ActiveRecord::Migration
  def change
    Item.transaction do
      CanceledItem.finalized.each do |item|
        # for some reason, many CanceledItems that have a vouchertype_id do NOT have an account code, so
        # fix that here.
        item.account_code_id ||= item.vouchertype.account_code_id if item.amount != 0
        item.save!
        RefundedItem.from_cancellation(item).save!
      end
    end
  end
end
