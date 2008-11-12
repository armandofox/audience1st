class SeparateUsername < ActiveRecord::Migration
  def self.up
    add_column :customers, :email, :string, :null => true, :default => nil
    change_column :customers, :street, :string, :null => true, :default => nil
    change_column :customers, :city, :string, :null => true, :default => nil
    change_column :customers, :state, :string, :null => true, :default => nil
    change_column :customers, :zip, :string, :null => true, :default => nil
    cmd = "UPDATE customers SET email=login WHERE login LIKE '%@%'"
    ActiveRecord::Base.connection.execute(cmd)
  end

  def self.down
    remove_column :customers, :email
  end
end
