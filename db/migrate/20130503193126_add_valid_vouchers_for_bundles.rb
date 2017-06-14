class AddValidVouchersForBundles < ActiveRecord::Migration
  def self.up
    # for each Bundle voucher, add a valid-voucher that enables it
    change_column :items, :showdate_id, :integer, :null => true, :default => nil
    change_column :valid_vouchers, :max_sales_for_type, :integer, :null => true, :default => nil
    Vouchertype.bundle_vouchertypes.select(&:valid?).each do |vt|
      vt.valid_vouchers.create!(
        :start_sales =>  vt.bundle_sales_start,
        :end_sales =>  [vt.bundle_sales_end, Time.at_end_of_season(vt.season)].min, # whichever is earlier
        :promo_code => vt.bundle_promo_code,
        :max_sales_for_type => nil)
    end
    ValidVoucher.update_all('max_sales_for_type=NULL', 'max_sales_for_type=0')
    remove_column :vouchertypes, :bundle_sales_start
    remove_column :vouchertypes, :bundle_sales_end
    remove_column :vouchertypes, :bundle_promo_code
    remove_column :vouchertypes, :valid_date
  end

  def self.down
    Vouchertype.bundle_vouchertypes.each do |vt|
      vt.valid_vouchers.delete_all
    end
  end
end
