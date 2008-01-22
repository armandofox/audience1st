class PerShowPatronNotes < ActiveRecord::Migration
  def self.up
    add_column :shows, :patron_notes, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :shows, :patron_notes
  end
end
