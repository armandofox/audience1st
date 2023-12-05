class AdjustDefaultMaxSalesPerTxn < ActiveRecord::Migration
  def change
    change_column :valid_vouchers, :max_sales_per_txn, :integer, :default => ValidVoucher::INFINITE, :allow_nil => false
  end
end
