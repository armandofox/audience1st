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
    Voucher.reset_column_information
  end

  def self.down
    add_column :vouchertypes, :is_bundle, :boolean, :default => false
    Vouchertype.reset_column_information
    Vouchertype.update_all("is_bundle=1", "type='BundleVouchertype'")
    remove_column :vouchertypes, :type
  end
end
