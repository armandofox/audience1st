class AddTypeToVouchers < ActiveRecord::Migration
  class Vouchertype < ActiveRecord::Base
  end
  def self.up
    add_column :vouchertypes, :type, :string
    Vouchertype.reset_column_information
    Vouchertype.update_all("type = 'SubscriberVouchertype'", "name not like '%comp%' and price=0")
    Vouchertype.update_all("type = 'CompVouchertype'", "name like '%tba%' or name like '%comp%'")
    Vouchertype.update_all("type = 'BundleVouchertype'", "is_bundle=1")
    Vouchertype.update_all("type = 'RevenueVouchertype'", "type IS NULL or type=''")
    remove_column :vouchertypes, :is_bundle
    add_column :vouchers, :price, :float, :null => false, :default => 0.0
    add_column :vouchers, :type, :string
    Voucher.reset_column_information
    ActiveRecord::Base.connection.execute "UPDATE vouchers v,vouchertypes vt SET v.price = vt.price WHERE v.vouchertype_id=vt.id"
    %w[Comp Revenue Subscriber Bundle].each do |w|
      ActiveRecord::Base.connection.execute "UPDATE vouchers v,vouchertypes vt SET v.type = '#{w}Voucher' WHERE vt.type = '#{w}Vouchertype'"
    end
  end

  def self.down
    add_column :vouchertypes, :is_bundle, :boolean, :default => false
    Vouchertype.reset_column_information
    Vouchertype.update_all("is_bundle=1", "type='BundleVouchertype'")
    remove_column :vouchers, :price
    remove_column :vouchertypes, :type
  end
end
