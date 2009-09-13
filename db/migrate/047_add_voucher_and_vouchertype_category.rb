class AddVoucherAndVouchertypeCategory < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle]
    add_column :vouchers, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle]
    Vouchertype.reset_column_information
    Voucher.reset_column_information
    Vouchertype.update_all("category='bundle'", "bundle=1")
    Vouchertype.update_all("category='comp'", "price=0 AND bundle=0 AND (name like '%Comp%' OR name like '%TBA%')")
    Vouchertype.update_all("category='subscriber'", "price=0 AND bundle=0 AND (category IS NULL OR category!='comp')")
    Vouchertype.update_all("category='revenue'", "category IS NULL or category=''")
    ActiveRecord::Base.connection.execute("UPDATE vouchers v JOIN vouchertypes vt ON v.vouchertype_id=vt.id SET v.category=vt.category")
    remove_column :vouchertypes, :bundle
  end

  def self.down
    add_column :vouchertypes, :bundle, :boolean, :null => false, :default => false
    Vouchertype.update_all('bundle=1', "category='bundle'")
    Vouchertype.remove_column :category
    Voucher.remove_column :category
  end
end
