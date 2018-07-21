class Slim < ActiveRecord::Migration
  def change
    drop_table :bulk_downloads
    drop_table :sessions
    drop_table :purchasemethods
    rename_column :txns, :purchasemethod_id, :purchasemethod
    rename_column :orders, :purchasemethod_id, :purchasemethod
  end
end
