class AddRecurringDonationToItems < ActiveRecord::Migration
  def change
    add_column :items, :recurring_donation_id, :integer
    add_foreign_key :items, :items, column: :recurring_donation_id
  end
end
