class AddReminderEmailsToOption < ActiveRecord::Migration
  def change
    add_column :options, :general_reminder_email_notes, :text
  end
end
