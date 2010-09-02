class RemoveNullColumnConstraints < ActiveRecord::Migration
  def self.up
    change_column :donations, :date, :datetime, :null => true, :default => nil
    change_column :showdates, :thedate, :datetime, :null => true, :default => nil
  end

  def self.down
  end
end
