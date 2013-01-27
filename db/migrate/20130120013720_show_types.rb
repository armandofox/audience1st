class ShowTypes < ActiveRecord::Migration
  def self.up
    add_column :shows, :event_type, :string, :null => false, :default => 'Regular Show'
    connection.execute 'UPDATE shows SET event_type="Special Event" WHERE shows.special=1'
    remove_column :shows, :special
  end

  def self.down
  end
end
