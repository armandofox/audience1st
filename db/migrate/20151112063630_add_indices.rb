class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :items, :bundle_id

    # since we're here...
    add_index :customers_labels, :label_id

    add_index :items, :vouchertype_id
    add_index :items, :bundle_id
    add_index :items, :account_code_id

    add_index :vouchertypes, :subscription
    add_index :vouchertypes, :walkup_sale_allowed
    add_index :vouchertypes, :category
    add_index :vouchertypes, :season
    add_index :vouchertypes, [:category, :season]

    add_index :orders, :customer_id
    add_index :orders, :purchaser_id

    add_index :showdates, :show_id

    add_index :txns, :customer_id

    add_index :valid_vouchers, :vouchertype_id
    add_index :valid_vouchers, :showdate_id
  end

end
