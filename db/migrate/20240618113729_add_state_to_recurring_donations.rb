class AddStateToRecurringDonations < ActiveRecord::Migration
  def change
    add_column :items, :state, :string
  end
end
