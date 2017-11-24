class RemoveNameFromAuthorization < ActiveRecord::Migration
  def change
    remove_column :authorizations, :name, :string
  end
end
