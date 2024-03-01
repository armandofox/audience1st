class CreateRecurringDonations < ActiveRecord::Migration
  def change
    create_table :recurring_donations do |t|
      t.belongs_to :account_code
      t.belongs_to :customer
      t.float    "amount",                         default: 0.0
      t.string   "comments",                       limit: 255
      t.timestamps null: false
    end

    add_reference :items, :recurring_donation
  end
end
