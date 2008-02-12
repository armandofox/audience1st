class DonationFixup < ActiveRecord::Migration

  # move account code from donation type to donation fund
  # substitute concept of purchasemethod (expanded with In Kind) for concept
  #  of donation type
  # for all existing donations, set purchasemethod correctly:
  #   - if 

  def self.up
    Purchasemethod.create!(:shortdesc => 'in_kind',
                           :description => "In Kind Goods/Services")
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('1','Web - Credit Card','web_cc')"
  end

  def self.down
  end
end
