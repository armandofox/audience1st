class BundleStartSales < ActiveRecord::Migration
  # This migration is a temporary hack to add start_sales/end_sales
  # fields to bundle vouchers.
  # The long term solution is to use valid_vouchers to regulate this,
  # as they are used to regulate sales of all other vouchers.
  
  def self.up
    t = Time.local(2007,1,1)
    add_column :vouchertypes, :bundle_sales_start, :datetime, :null => false, :default => t.to_formatted_s(:db)
    add_column :vouchertypes, :bundle_sales_end, :datetime, :null => false, :default => (t + 1.year).to_formatted_s(:db)
  end

  def self.down
    remove_column :vouchertypes, :bundle_sales_start
    remove_column :vouchertypes, :bundle_sales_end
  end
end
