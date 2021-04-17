class AddReminderToShows < ActiveRecord::Migration
  def change
    add_column :shows, :reminder_type, :string, :null => false, :default => Show::REMINDERS.first
  end
end
