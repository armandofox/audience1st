class CreateRecurringDonation < ActiveRecord::Migration
  def change
    create_table :recurring_donations do |t|
      t.belongs_to :customer
      t.belongs_to :account_code
      t.belongs_to :processed_by
      t.string :stripe_price_oid, :allow_nil => false
      t.string :state           # 'pending', 'active', 'stopped'
      t.integer :amount         # in whole dollars
      t.timestamps
    end
    change_table :items do |t|
      t.belongs_to :recurring_donation
    end
  end
end
