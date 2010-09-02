class RemoveNullColumnConstraints < ActiveRecord::Migration
  def self.up
    change_column :donations, :date, :datetime, :null => true, :default => nil
    change_column :showdates, :thedate, :datetime, :null => true, :default => nil
    change_column :visits, :thedate, :datetime, :null => true, :default => nil
    rename_column :imports, :completed_by_id, :customer_id
  end

  def self.down
  end
end
