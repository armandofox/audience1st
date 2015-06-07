class PerOrderServiceCharge < ActiveRecord::Migration
  def self.up
    add_column :options, :subscription_order_service_charge, :integer, :default => 0
    add_column :options, :subscription_order_service_charge_description, :string, :null => true, :default => nil
    add_column :options, :subscription_order_service_charge_account_code, :string, :null => true, :default => nil
    add_column :options, :regular_order_service_charge, :integer, :default => 0
    add_column :options, :regular_order_service_charge_description, :string, :null => true, :default => nil
    add_column :options, :regular_order_service_charge_account_code, :string, :null => true, :default => nil
    add_column :options, :classes_order_service_charge, :integer, :default => 0
    add_column :options, :classes_order_service_charge_description, :string, :null => true, :default => nil
    add_column :options, :classes_order_service_charge_account_code, :string, :null => true, :default => nil
  end

  def self.down
  end
end
