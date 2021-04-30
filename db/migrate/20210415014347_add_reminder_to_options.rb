class AddReminderToOptions < ActiveRecord::Migration
  def change
  	add_column :options, :reminder_emails, :string, :default => "Never"
  end
end
