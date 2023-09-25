class AdjustInfinityInMaxSalesForType < ActiveRecord::Migration
  # previous code used '999' as an upper bound on max_sales_for_type that means "infinity".
  # it should be 10_000 to be consistent with the value of ValidVoucher::INFINITE.
  def change
    ValidVoucher.where("max_sales_for_type=999").
      update_all(:max_sales_for_type => ValidVoucher::INFINITE)
    ValidVoucher.where("max_sales_per_txn=999").
      update_all(:max_sales_per_txn => ValidVoucher::INFINITE)
  end
end
