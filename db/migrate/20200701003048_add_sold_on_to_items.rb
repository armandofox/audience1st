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
    offset = 0
    refunds = {}
    while (1)
      items =  Item.finalized.offset(offset).limit(500)
      offset += 500
      break if items.empty?
      items.each do |i|
        case i
        when CanceledItem
          if i.amount != 0 && i.account_code_id.blank?
            i.update_column(:account_code_id, i.vouchertype.account_code_id)
          end
          cancel_time = i.updated_at
          i.update_column(:sold_on, i.order.sold_on)
          refunds[i.id] = cancel_time
        when RefundedItem
          # do nothing
        else
          i.update_column(:sold_on, i.order.sold_on)
        end
      end
      print "."
    end
    puts "Creating #{refunds.keys.size} refunds"
    refunds.each_pair do |id, cancel_time|
      i = Item.find(id)
      # create the Refund transaction
      ref = RefundedItem.from_cancellation(i)
      ref.sold_on = cancel_time
      ref.save!
    end
    puts "\n#{refunds_created} refund items created"
  end
end
