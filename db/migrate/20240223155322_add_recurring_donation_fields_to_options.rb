class AddRecurringDonationFieldsToOptions < ActiveRecord::Migration
  def change
    add_column :options, :allow_recurring_donations, :boolean, default: false
    add_column :options, :default_donation_type, :string, default: "One Time"
    add_column :options, :recurring_donation_contact_emails, :text
    add_column :options, :notify_theatre_about_new_recurring_donation, :boolean, default: true
    add_column :options, :notify_threate_about_failed_recurring_donation_charge, :boolean, default: true
  end
end
