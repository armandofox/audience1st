class RemoveReminderFromShows < ActiveRecord::Migration
  def change
  	remove_column :shows, :reminder_type
  end
end
