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
    count = 0
    Item.reset_column_information
    Item.finalized.each do |i|
      if i.amount != 0 && i.account_code_id.blank?
        i.update_column(:account_code_id, i.vouchertype.account_code_id)
      end
      i.update_column(:sold_on, i.order.sold_on)
      i.reload
      puts "Item #{i.id} still has null sold_on" if i.sold_on.blank?

      count += 1
      print "." if count % 100 == 0
    end
    puts "Examined #{count} records"
  end
end
