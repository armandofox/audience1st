class AddDefaultRetailAccountCodeToOptions < ActiveRecord::Migration
  def self.up
    add_column :options, :default_retail_account_code, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :options, :default_retail_account_code
  end
end
