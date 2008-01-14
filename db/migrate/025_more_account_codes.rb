class MoreAccountCodes < ActiveRecord::Migration
  def self.up
    p = Purchasemethod.find_by_shortdesc("cust_web").id
    add_column :donation_types, :account_code, :string, :limit => 8, :null => false, :default => ""
    change_column :vouchertypes, :account_code, :string, :limit => 8, :null => false, :default => ""
    add_column :donations, :purchasemethod_id, :integer, :null => false, :default => p
  end

  def self.down
    remove_column :donations, :purchasemethod_id
    remove_column :donation_types, :account_code
  end
end
