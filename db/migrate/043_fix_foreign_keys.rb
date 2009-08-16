class FixForeignKeys < ActiveRecord::Migration

  def self.up
    rename_column :donations, :processed_by, :processed_by_id
    rename_column :vouchers, :processed_by, :processed_by_id
    drop_table :custom_reports
    drop_table :donation_types
    remove_column :vouchers, :valid_date
  end

  def self.down
    rename_column :donations, :processed_by_id, :processed_by
    rename_column :vouchers, :processed_by_id, :processed_by
    add_column :vouchers, :valid_date
    ActiveRecord::Base.connection.execute <<EOQ
        UPDATE vouchers v,vouchertypes vt
        SET v.valid_date=vt.valid_date
        WHERE v.vouchertype_id = vt.id
EOQ
  end
end
