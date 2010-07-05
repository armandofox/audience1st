class SubscriptionPromoCode < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :bundle_promo_code, :string, :null => true, :default => nil
    rename_column :valid_vouchers, :password, :promo_code
  end

  def self.down
    remove_column :vouchertypes, :bundle_promo_code
    rename_column :valid_vouchers, :promo_code, :password
  end
end
