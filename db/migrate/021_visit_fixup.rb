class VisitFixup < ActiveRecord::Migration
  def self.up
    remove_column :visits, :created_at
    add_column :visits, :thedate, :date, :null => false
    remove_column :customers, :is_contact
    add_column :customers, :best_way_to_contact, :string, :null => true, :default => nil
  end

  def self.down
    add_column :visits, :created_at, :datetime
    remove_column :visits, :thedate
    add_column :customers, :is_contact, :boolean, :default => false
    remove_column :customers, :best_way_to_contact
  end
end
