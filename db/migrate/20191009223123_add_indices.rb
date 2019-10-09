class AddIndices < ActiveRecord::Migration
  def change
    add_index :customers, :ticket_sales_import_id
    add_index :customers_labels, [:customer_id, :label_id], :unique => true
    %w(vouchertype_id customer_id showdate_id processed_by_id bundle_id account_code_id order_id).each do |key|
      add_index :items, key
    end
    %w(customer_id processed_by_id purchaser_id ticket_sales_import_id).each do |key|
      add_index :orders, key
    end
    add_index :showdates, :show_id
    add_index :showdates, :seatmap_id
    add_index :ticket_sales_imports, :processed_by_id
    %w(customer_id entered_by_id show_id showdate_id voucher_id order_id).each do |key|
      add_index :txns, key
    end
    add_index :valid_vouchers, :showdate_id
    add_index :valid_vouchers, :vouchertype_id
    add_index :vouchertypes, :account_code_id
  end
end
