# This migration is was needed because we found that the `reminder_types` column was duplicated
# due to adding a "limig: 255" field in one migration, but not including in an updated migration later
# so a new migration wasm ade to try and remove that duplicate column but it removed both
# this migration is to put the column back

class AddReminderTypeToShows < ActiveRecord::Migration
  def change
    add_column :shows, :reminder_type, :string, :null => false, :default => Show::REMINDERS.first
  end
end
