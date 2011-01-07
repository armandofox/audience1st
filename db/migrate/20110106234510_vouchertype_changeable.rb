class VouchertypeChangeable < ActiveRecord::Migration
  def self.up
    add_column :vouchertypes, :changeable, :boolean, :null => false, :default => false
    Vouchertype.update_all('changeable=1', "category='subscriber' OR category='comp'")
    remove_column :vouchers, :changeable
  end

  def self.down
    add_column :vouchers, :changeable, :boolean, :null => false, :default => false
    connection.execute("UPDATE vouchers v JOIN vouchertypes vt ON v.vouchertype_id=vt.id SET v.changeable=1 WHERE vt.changeable=1")
    remove_column :vouchertypes, :changeable
  end
end
