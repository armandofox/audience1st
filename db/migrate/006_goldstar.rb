class Goldstar < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :external_key, :integer, :default => 0
    unless Vouchertype.find(:first, :conditions => "name LIKE '%goldstar%'")
      Vouchertype.create(:name => "Goldstar 1/2 price",
                         :price => 10.00,
                         :offer_public => false,
                         :is_bundle => false,
                         :is_subscription => false,
                         :included_vouchers => {},
                         :comments => '')
    end
  end

  def self.down
    remove_column :vouchers, :external_key
  end
end
