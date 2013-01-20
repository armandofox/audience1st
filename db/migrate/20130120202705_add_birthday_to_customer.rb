class AddBirthdayToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :birthday, :date, :null => true, :default => nil
  end

  def self.down
  end
end
