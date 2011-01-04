class RemoveObsoleteVouchertypeDates < ActiveRecord::Migration
  def self.up
    begin
      remove_column :vouchertypes, :expiration_date
      remove_column :vouchertypes, :valid_date
    rescue
    end
  end

  def self.down
    add_column :vouchertypes, :expiration_date, :datetime, :null => true, :default => nil
    add_column :vouchertypes, :valid_date, :datetime, :null => true, :default =>  nil
    Vouchertype.find(:all).each do |v|
      v.update_attributes(:expiration_date => Date.civil(v.season, 12, 31),
        :valid_date => Date.civil(v.season,1,1))
    end
  end
end
