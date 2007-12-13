class LongCommentsForVisits < ActiveRecord::Migration
  def self.up
    change_column :visits, :additional_notes, :text, :null=>true, :default=>nil
    add_column :vouchertypes, :account_code, :string, :limit => 8, :null => true, :default => nil
  end

  def self.down
    change_column :visits, :additional_notes, :string,:null=>true,:default=>nil
    remove_column :vouchertypes, :account_code
  end
end
