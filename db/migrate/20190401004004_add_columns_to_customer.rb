class AddColumnsToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :token, :string
    add_column :customers, :token_created_at, :datetime
  end
end
