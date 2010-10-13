class AddSpecialToShows < ActiveRecord::Migration
  def self.up
    add_column :shows, :special, :boolean, :null => true, :default => nil
  end

  def self.down
    remove_column :shows, :special
  end
end
