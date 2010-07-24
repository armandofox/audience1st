class AddShowNameToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :show_id, :integer, :null => true, :default => nil
    change_column :imports, :number_of_records, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :imports, :show_id
    change_column :imports, :number_of_records, :integer, :null => true, :default => nil
  end
end
