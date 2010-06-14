class AddShowAndShowdateDescription < ActiveRecord::Migration
  def self.up
    add_column :shows, :description, :string, :null => true, :default => nil
    add_column :showdates, :description, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :shows, :description
    remove_column :showdates, :description
  end
end
