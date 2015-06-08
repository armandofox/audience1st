class PerOrderServiceCharge < ActiveRecord::Migration
  def self.up

    add_column :orders, :retail_items, :text, :null => true, :default => nil

    %w(subscription regular classes).each do |type|
      add_column :options, "#{type}_order_service_charge", :float, :default => 0.0
      add_column :options, "#{type}_order_service_charge_description", :string, :null => true, :default => nil
      add_column :options, "#{type}_order_service_charge_account_code", :integer, :null => false, :default => 0
    end
    
    Option.reset_column_information

    # Set Option.default_{donation,retail,etc}_account_code to the ID of
    # the appropriate AccountCode object, else validation fails

    default_account_code_id = AccountCode.default_account_code_id
    Option.first.update_attributes!(
      :default_retail_account_code =>
      (AccountCode.find_or_create_by_code(Option.default_retail_account_code)).id,

      :default_donation_account_code => (AccountCode.find_or_create_by_code(Option.default_donation_account_code)).id,

      :default_donation_account_code_with_subscriptions => (AccountCode.find_or_create_by_code(Option.default_donation_account_code_with_subscriptions)).id,

      :subscription_order_service_charge_account_code => default_account_code_id,
      :regular_order_service_charge_account_code => default_account_code_id,
      :classes_order_service_charge_account_code => default_account_code_id
      )
  end

  def self.down
  end
end
