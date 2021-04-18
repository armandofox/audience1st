class RemoveReminderFromShows < ActiveRecord::Migration
  def change
  	remove_column :shows, :reminder_type, :string, :limit => 255, :default => "Never", :null => false
  end
end
