class AddSoldOnToItems < ActiveRecord::Migration
  def change

    if Option.first.try(:venue) =~ /Altarena/i
      execute %q{
INSERT INTO "altarena"."vouchertypes"("id","name","price","created_at","comments","offer_public","subscription","included_vouchers","walkup_sale_allowed","fulfillment_needed","category","season","changeable","account_code_id","display_order")
VALUES
(697,E'Unknown Comp 697',0,E'2020-01-30 17:03:35.787283',E'',0,FALSE,NULL,FALSE,FALSE,E'comp',2020,FALSE,1,0);}
      execute %q{
INSERT INTO "altarena"."vouchertypes"("id","name","price","created_at","comments","offer_public","subscription","included_vouchers","walkup_sale_allowed","fulfillment_needed","category","season","changeable","account_code_id","display_order")
VALUES
(699,E'Unknown Comp 699',0,E'2020-01-30 17:03:35.787283',E'',0,FALSE,NULL,FALSE,FALSE,E'comp',2020,FALSE,1,0);}
      execute %q{
INSERT INTO "altarena"."vouchertypes"("id","name","price","created_at","comments","offer_public","subscription","included_vouchers","walkup_sale_allowed","fulfillment_needed","category","season","changeable","account_code_id","display_order")
VALUES
(704,E'Unknown Comp 704',0,E'2020-01-30 17:03:35.787283',E'',0,FALSE,NULL,FALSE,FALSE,E'comp',2020,FALSE,1,0);}
    end


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
          ref.save(validate: false)
          i.save(validate: false)
          i.update_attribute(:updated_at, cancel_time)
          refunds_created += 1
        when RefundedItem
          # do nothing
        else
          orig_updated_at = i.updated_at
          i.sold_on = i.order.sold_on
          i.save(validate: false)
          i.update_attribute(:updated_at, orig_updated_at)
        end
      end
      print "."
    end
    puts "\n#{refunds_created} refund items created"
  end
end
