class RenameMaxSalesToMaxAdvanceSales < ActiveRecord::Migration
  def change
    rename_column :showdates, :max_sales, :max_advance_sales
  end
end
