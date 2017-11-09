class RemoveBcryptedPasswordFromCustomers < ActiveRecord::Migration
  def change
    remove_column :customers, :bcrypted_password, :string
  end
end
