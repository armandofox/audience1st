class RemoveDeadFields < ActiveRecord::Migration
  def self.up
    say "Removing obsolete fields from customers"
    remove_column :customers, :is_current_subscriber
    remove_column :customers, :fb_user_id
    remove_column :customers, :email_hash

    say "Removing txn_types table"
    add_column :txns, :txn_type, :string
    Txn.connection.execute %Q{
        UPDATE txns t JOIN txn_types tt ON t.txn_type_id=tt.id
        SET t.txn_type=tt.shortdesc}
    remove_column :txns, :txn_type_id
    drop_table :txn_types

    say "Removing vouchers.ship_to_purchaser and vouchers.gift_purchaser_id"
    remove_column :items, :ship_to_purchaser
    remove_column :items, :gift_purchaser_id
  end

  def self.down
  end
end
