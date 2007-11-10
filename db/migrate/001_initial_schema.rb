class InitialSchema < ActiveRecord::Migration
  def self.up

    create_table "customers", :force => false do |t|
      t.column "first_name", :string, :limit => 64, :default => "", :null => false
      t.column "last_name", :string, :limit => 64, :default => "", :null => false
      t.column "street", :string, :limit => 80, :default => "", :null => false
      t.column "city", :string, :limit => 64, :default => "", :null => false
      t.column "state", :string, :limit => 8, :default => "CA", :null => false
      t.column "zip", :string, :limit => 12, :default => "", :null => false
      t.column "day_phone", :string, :limit => 50, :default => "", :null => false
      t.column "eve_phone", :string, :limit => 50, :default => "", :null => false
      t.column "phplist_user_user_id", :integer, :default => 0, :null => false
      t.column "login", :string, :limit => 30, :default => "", :null => false
      t.column "hashed_password", :string, :default => "", :null => false
      t.column "salt", :string, :limit => 12, :default => "", :null => false
      t.column "role", :integer, :limit => 4, :default => 0, :null => false
      t.column "created_on", :datetime, :null => false
      t.column "updated_on", :datetime, :null => false
      t.column "member_type", :integer, :default => 0, :null => false
      t.column "comments", :text, :default => "", :null => false
      t.column "oldid", :integer, :limit => 15, :default => 0, :null => false
    end

    create_table "donation_funds", :force => false do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
    end

    create_table "donation_types", :force => false do |t|
      t.column "name", :string, :limit => 40, :default => "", :null => false
    end

    create_table "donations", :force => false do |t|
      t.column "date", :date, :null => false
      t.column "amount", :float, :default => 0.0, :null => false
      t.column "donation_type_id", :integer, :default => 0, :null => false
      t.column "donation_fund_id", :integer, :default => 0, :null => false
      t.column "comment", :string, :default => "", :null => false
      t.column "customer_id", :integer, :default => 0, :null => false
    end

    create_table "purchasemethods", :force => false do |t|
      t.column "description", :string, :default => "", :null => false
      t.column "offer_public", :boolean, :default => false, :null => false
      t.column "shortdesc", :string, :limit => 10, :default => "?purch?", :null => false
    end

    create_table "showdates", :force => false do |t|
      t.column "thedate", :datetime
      t.column "end_advance_sales", :datetime
      t.column "max_sales", :integer, :default => 0, :null => false
      t.column "show_id", :integer, :default => 0, :null => false
    end

    create_table "shows", :force => false do |t|
      t.column "name", :string
      t.column "opening_date", :date
      t.column "closing_date", :date
      t.column "house_capacity", :integer, :limit => 5, :default => 0, :null => false
      t.column "created_on", :datetime, :null => false
    end

    create_table "txn_types", :force => false do |t|
      t.column "desc", :string, :limit => 100, :default => "Other"
      t.column "shortdesc", :string, :limit => 10, :default => "???", :null => false
    end

    create_table "txns", :force => false do |t|
      t.column "customer_id", :integer, :default => 1, :null => false
      t.column "entered_by_id", :integer, :default => 1, :null => false
      t.column "txn_date", :datetime
      t.column "txn_type_id", :integer, :limit => 10, :default => 0, :null => false
      t.column "show_id", :integer
      t.column "showdate_id", :integer
      t.column "purchasemethod_id", :integer
      t.column "voucher_id", :integer, :default => 0, :null => false
      t.column "dollar_amount", :float, :default => 0.0, :null => false
      t.column "comments", :string
    end

    create_table "valid_vouchers", :force => false do |t|
      t.column "offer_public", :boolean
      t.column "showdate_id", :integer
      t.column "vouchertype_id", :integer
      t.column "password", :string
      t.column "start_sales", :datetime
      t.column "end_sales", :datetime
      t.column "max_sales_for_type", :integer, :limit => 6, :default => 0, :null => false
    end

    create_table "vouchers", :force => false do |t|
      t.column "vouchertype_id", :integer, :limit => 10, :default => 0, :null => false
      t.column "customer_id", :integer, :limit => 12, :default => 0, :null => false
      t.column "showdate_id", :integer, :default => 0, :null => false
      t.column "expiration_date", :datetime
      t.column "purchasemethod_id", :integer, :limit => 10, :default => 0, :null => false
      t.column "comments", :string
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
    end

    create_table "vouchertypes", :force => false do |t|
      t.column "name", :string
      t.column "price", :float, :default => 0.0
      t.column "created_on", :datetime
      t.column "comments", :text
      t.column "offer_public", :boolean, :default => false, :null => false
      t.column "is_bundle", :boolean, :default => false
      t.column "is_subscription", :boolean, :default => false, :null => false
      t.column "included_vouchers", :string, :default => "", :null => false
      t.column "promo_code", :string, :limit => 20, :default => "", :null => false
    end
  end

  def self.down
  end
end
