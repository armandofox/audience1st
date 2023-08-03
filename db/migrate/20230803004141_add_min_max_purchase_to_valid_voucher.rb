class AddMinMaxPurchaseToValidVoucher < ActiveRecord::Migration
  def change
    change_table :valid_vouchers do |t|
      t.integer :min_sales_per_txn, :default => 1, :allow_nil => false
      t.integer :max_sales_per_txn, :default => 999, :allow_nil => false
    end
  end
end
