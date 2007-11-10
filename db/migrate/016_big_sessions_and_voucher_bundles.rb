class BigSessionsAndVoucherBundles < ActiveRecord::Migration

  # temporary workaround for the fact that something is weird about sessions
  # that makes them get too large, and that the encoding of bundle voucheryptes
  # overflows the default string size.
  
  def self.up
    change_column :sessions, :data, :text
    change_column :vouchertypes, :included_vouchers, :text
  end

  def self.down
    change_column :sessions, :data, :string
    change_column :vouchertypes, :included_vouchers, :string
  end
end
