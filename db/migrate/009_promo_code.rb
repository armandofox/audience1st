class PromoCode < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :promo_code, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :vouchers, :promo_code
  end
end
