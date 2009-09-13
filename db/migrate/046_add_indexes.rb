class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index 'customers', :last_name
    add_index 'customers', :first_name
    add_index 'valid_vouchers', :start_sales
    add_index 'valid_vouchers', [:showdate_id,:vouchertype_id]
  end

  def self.down
    remove_index 'customers', :last_name
    remove_index 'customers', :first_name
    remove_index 'valid_vouchers', :start_sales
    add_index 'valid_vouchers', [:showdate_id,:vouchertype_id]
  end
end
