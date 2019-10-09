class AddIndices < ActiveRecord::Migration
  def try_add_index(table, col)
    unless ActiveRecord::Base.connection.index_exists? table,col
      add_index table,col
    else
      puts "WARNING: index #{table}:#{col} already exists"
    end
  end
  def change
    try_add_index :customers, :ticket_sales_import_id
    try_add_index :customers_labels, [:customer_id, :label_id]
    %w(vouchertype_id customer_id showdate_id processed_by_id bundle_id account_code_id order_id).each do |key|
      try_add_index :items, key
    end
    %w(customer_id processed_by_id purchaser_id ticket_sales_import_id).each do |key|
      try_add_index :orders, key
    end
    try_add_index :showdates, :show_id
    try_add_index :showdates, :seatmap_id
    try_add_index :ticket_sales_imports, :processed_by_id
    %w(customer_id entered_by_id show_id showdate_id voucher_id order_id).each do |key|
      try_add_index :txns, key
    end
    try_add_index :valid_vouchers, :showdate_id
    try_add_index :valid_vouchers, :vouchertype_id
    try_add_index :vouchertypes, :account_code_id
  end
end
