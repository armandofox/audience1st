class MaintenanceModeBoolean < ActiveRecord::Migration
  def change
    remove_column :options, :encrypted_maintenance_password, :staff_access_only
    add_column :options, :staff_access_only, :boolean, :default => false
    remove_column :options, :venue_id
  end
end
