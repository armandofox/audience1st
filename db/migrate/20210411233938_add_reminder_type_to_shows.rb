class AddReminderTypeToShows < ActiveRecord::Migration
  def change
  	add_column :shows, :reminder_type, :string, :null => false, :default => "Never"
  end
end
