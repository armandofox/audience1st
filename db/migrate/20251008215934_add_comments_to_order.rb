class AddCommentsToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :comments, :string, :null => false, :default => ''
  end
end
