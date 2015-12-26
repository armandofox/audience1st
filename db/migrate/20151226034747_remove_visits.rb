class RemoveVisits < ActiveRecord::Migration
  def self.up
    remove_column :shows, :created_on

    drop_table :visits
    remove_column :options, :followup_visit_reminder_lead_time
    remove_column :customers, :oldid
    remove_column :customers, :referred_by_id
    remove_column :customers, :referred_by_other

    change_column_default :showdates, :created_at, nil
    change_column_default :showdates, :updated_at, nil
    change_column_default :shows, :listing_date, nil
    change_column_default :shows, :created_at, nil
    change_column_default :shows, :updated_at, nil
    change_column_default :valid_vouchers, :created_at, nil
    change_column_default :valid_vouchers, :updated_at, nil

    # add some indices while we're here

    add_index :customers, :street
    add_index :customers, :city
    add_index :customers, :state
    add_index :customers, :zip
    add_index :customers, :day_phone
    add_index :customers, :eve_phone
    add_index :customers, :role
    add_index :customers, :comments
    
    
  end

  def self.down
  end
end
