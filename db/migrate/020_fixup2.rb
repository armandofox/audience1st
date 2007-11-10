class Fixup2 < ActiveRecord::Migration
  def self.up
    add_column :vouchers, :expiration_date, :datetime, :null => false, :default => "#{Time.parse('12/31/2008').to_s(:db)}"
    Customer.walkup_customer.update_attributes(:street => "DO NOT MODIFY",
                                                :city => "DO NOT MODIFY",
                                                :state => "CA",
                                                :zip => "DO NOT MODIFY")
                                               
  end

  def self.down
  end
end
