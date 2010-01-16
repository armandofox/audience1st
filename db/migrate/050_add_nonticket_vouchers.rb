class AddNonticketVouchers < ActiveRecord::Migration
  def self.up
    change_column :vouchers, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle, :nonticket]
    change_column :vouchertypes, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle, :nonticket]
    change_column :vouchers, :used, :boolean, :null => false, :default => false
  end

  def self.down
    change_column :vouchers, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle]
    change_column :vouchertypes, :category, :enum, :limit => [:revenue, :comp, :subscriber, :bundle]
    change_column :vouchers, :used, :datetime, :null => true, :default => nil
  end
end
