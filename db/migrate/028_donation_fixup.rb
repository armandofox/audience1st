class DonationFixup < ActiveRecord::Migration

  # move account code from donation type to donation fund
  # substitute concept of purchasemethod (expanded with In Kind) for concept
  #  of donation type
  # for all existing donations, set purchasemethod correctly:
  #   - if 

  # other random schema improvements:
  #  add a "landing page URL" field to Show info, for exporting calendar etc
  

  def self.up
    ActiveRecord::Base.connection.execute "INSERT INTO `purchasemethods` (`id`,`description`,`shortdesc`) VALUES ('10','In-Kind Goods or Services', 'in_kind')"
    add_column :shows, :landing_page_url,:string,:null => true, :default =>nil
    change_column :options, :value, :text
  end

  def self.down
  end
end
