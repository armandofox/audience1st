class Import < ActiveRecord::Base;    end
class CustomerImport < Import ; end
class GoldstarCsvImport < Import ; end
class BrownPaperTicketsImport < Import ; end
class TbaWebtixImport < Import ; end
class GoldstarXmlImport < Import ; end
class TicketSalesImport < ActiveRecord::Base
  attr_accessible :processed_by_id, :created_at, :updated_at, :vendor,:tickets_sold, :processed_by_id
end
class MigrateImports < ActiveRecord::Migration
  def change
    Import.all.each do |i|
      next if i.type === 'CustomerImport'
      num_tix = Voucher.joins(:vouchertype).
        where(:showdate_id => i.showdate_id).
        where("vouchertypes.name LIKE ?", "%Goldstar%").count
      TicketSalesImport.create!(
        :vendor => 'Goldstar',
        :tickets_sold => num_tix,
        :processed_by_id => i.customer_id,
        :created_at => i.completed_at,
        :updated_at => i.completed_at)
    end
    drop_table 'imports'
  end
end
