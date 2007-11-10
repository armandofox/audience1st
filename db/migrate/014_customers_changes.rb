class CustomersChanges < ActiveRecord::Migration
  def self.up
    change_column :customers, :login, :string, :null => true, :default =>  nil
    remove_column :customers, :member_type
  end

  def self.down
  end
end
