class AddAccountCodeToDonationFund < ActiveRecord::Migration
  def self.up
    add_column :donation_funds, :account_code, :string, :null => false, :default => ""
    add_column :donation_funds, :description, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :donation_funds, :account_code
    remove_column :donation_funds, :description
  end
end
