class MoreNoshow < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :processed_by, :integer, :null => false, :default => Customer.generic_customer.id
    add_column :customers, :e_blacklist, :boolean, :null => true, :default => false
    add_column :vouchertypes, :walkup_sale_allowed, :boolean, :null => true, :default => true
  end

  def self.down
    remove_column :vouchers, :processed_by
    remove_column :customers, :e_blacklist
    remove_column :vouchertypes, :walkup_sale_allowed
  end
end
