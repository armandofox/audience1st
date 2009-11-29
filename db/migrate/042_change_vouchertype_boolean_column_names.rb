class ChangeVouchertypeBooleanColumnNames < ActiveRecord::Migration
  def self.up
    change_column :vouchertypes, :is_bundle, :boolean, :null => true, :default => nil
    rename_column :vouchertypes, :is_bundle, :bundle
    change_column :vouchertypes, :is_subscription, :boolean, :null => true, :default => nil
    rename_column :vouchertypes, :is_subscription, :subscription
    change_column :vouchertypes, :walkup_sale_allowed, :boolean, :null => true, :default => true
  end

  def self.down
    rename_column :vouchertypes, :subscription, :is_subscription
    rename_column :vouchertypes, :bundle, :is_bundle
  end
end
