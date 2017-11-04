class AddBcryptedPasswordToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :bcrypted_password, :string
  end
end
