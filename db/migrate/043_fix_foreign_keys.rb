class FixForeignKeys < ActiveRecord::Migration

  def self.up
    rename_column :donations, :processed_by, :processed_by_id
    rename_column :vouchers, :processed_by, :processed_by_id
    drop_table :custom_reports
    drop_table :donation_types
  end

  def self.down
    rename_column :donations, :processed_by_id, :processed_by
    rename_column :vouchers, :processed_by_id, :processed_by
  end
end
