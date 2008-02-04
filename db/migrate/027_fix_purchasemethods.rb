class FixPurchasemethods < ActiveRecord::Migration
  def self.up
    remove_column :purchasemethods, :offer_public
    Purchasemethod.delete_all
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('1','Web - Credit Card','web_cc')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('2','No payment required','none')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('3','Box office - Credit Card','box_cc')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('4','Box office - Cash','box_cash')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('5','Box office - Check','box_chk')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('6','Payment Due','pmt_due')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('7','External Vendor','ext')"
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('8','Part of a package','bundle')"
    ActiveRecord::Base.connection.execute  "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('9','Other','?purch?')"

    do_updates(1, [2])
    do_updates(2, [3,7,11])
    do_updates(3, [14,9])
    # 4,5 stay same
    do_updates(4, [15])
    do_updates(9, [6,13])
    # set Goldstar
    Voucher.update_all "purchasemethod_id=7", "vouchertype_id IN (42,59)"
  end

  def self.do_updates(newid,oldids)
    [Donation,Txn,Voucher].each do |model|
      model.update_all "purchasemethod_id=#{newid}", oldids.map { |x| "purchasemethod_id=#{x}" }.join(" OR ")
    end
  end
     

  def self.down
  end
end
