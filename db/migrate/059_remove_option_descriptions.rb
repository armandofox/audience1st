class RemoveOptionDescriptions < ActiveRecord::Migration
  def self.up
    remove_column :options, :description
  end

  def self.down
    add_column :options, :description, :string, :null => true, :default => nil
  end
end
