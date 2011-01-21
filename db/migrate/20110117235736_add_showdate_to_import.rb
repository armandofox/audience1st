class AddShowdateToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :showdate_id, :integer, :null => true, :default => nil
    change_column :vouchers, :external_key, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :imports, :showdate_id
    change_column :vouchers, :external_key, :integer, :null => true, :default => nil
  end
end
