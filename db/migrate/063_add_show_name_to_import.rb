class AddShowNameToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :show_id, :integer, :null => true, :default => nil
  end

  def self.down
    remove_column :imports, :show_id
  end
end
