class ExpirationDatesForVouchers < ActiveRecord::Migration
  def self.up
    deftime = Time.local(2007,1,1)
    add_column :vouchers, :valid_date, :datetime, :null => false, :default => deftime
    # we do this by raw SQL because it is faster and to prevent the
    # updated_on field of these records from being touched.
    ActiveRecord::Base.connection.execute("UPDATE vouchers v,vouchertypes vt SET v.expiration_date=vt.expiration_date, v.valid_date=vt.valid_date WHERE v.vouchertype_id=vt.id")
    add_column :vouchers, :sold_on, :datetime, :null => true, :default => nil
    ActiveRecord::Base.connection.execute("UPDATE vouchers v SET v.sold_on=v.updated_on WHERE 1")
  end

  def self.down
    remove_column :vouchers, :valid_date
    remove_column :vouchers, :sold_on
  end
end
