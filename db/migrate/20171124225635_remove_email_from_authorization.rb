class RemoveEmailFromAuthorization < ActiveRecord::Migration
  def change
    remove_column :authorizations, :email, :string
  end
end
