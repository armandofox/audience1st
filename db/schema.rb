# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 49) do

  create_table "customers", :force => true do |t|
    t.string   "first_name",             :limit => 64,                                                                                                                                                  :default => "",                    :null => false
    t.string   "last_name",              :limit => 64,                                                                                                                                                  :default => "",                    :null => false
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "day_phone"
    t.string   "eve_phone"
    t.integer  "phplist_user_id",                                                                                                                                                                       :default => 0,                     :null => false
    t.string   "login"
    t.string   "hashed_password",                                                                                                                                                                       :default => ""
    t.string   "salt",                   :limit => 12,                                                                                                                                                  :default => ""
    t.integer  "role",                                                                                                                                                                                  :default => 0,                     :null => false
    t.datetime "created_on",                                                                                                                                                                                                               :null => false
    t.datetime "updated_on",                                                                                                                                                                                                               :null => false
    t.text     "comments",               :limit => 2147483647
    t.integer  "oldid",                                                                                                                                                                                 :default => 0
    t.boolean  "blacklist",                                                                                                                                                                             :default => false
    t.integer  "validation_level",                                                                                                                                                                      :default => 0
    t.datetime "last_login",                                                                                                                                                                            :default => '2007-04-06 15:40:20', :null => false
    t.boolean  "e_blacklist",                                                                                                                                                                           :default => false
    t.integer  "referred_by_id"
    t.string   "referred_by_other"
    t.enum     "formal_relationship",    :limit => [:None, :"Board Member", :"Former Board Member", :"Board President", :"Former Board President", :"Honorary Board Member", :"Emeritus Board Member"], :default => :None
    t.enum     "member_type",            :limit => [:None, :Regular, :Sustaining, :Life, :"Honorary Life"],                                                                                             :default => :None
    t.string   "company"
    t.string   "title"
    t.string   "company_address_line_1"
    t.string   "company_address_line_2"
    t.string   "company_city"
    t.string   "company_state"
    t.string   "company_zip"
    t.string   "work_phone"
    t.string   "cell_phone"
    t.string   "work_fax"
    t.string   "company_url"
    t.string   "best_way_to_contact"
    t.boolean  "is_current_subscriber",                                                                                                                                                                 :default => false
    t.string   "email"
  end

  add_index "customers", ["first_name"], :name => "index_customers_on_first_name"
  add_index "customers", ["last_name"], :name => "index_customers_on_last_name"

  create_table "donation_funds", :force => true do |t|
    t.string "name",         :limit => 40, :default => "", :null => false
    t.string "account_code",               :default => "", :null => false
    t.string "description"
  end

  create_table "donations", :force => true do |t|
    t.date     "date",                               :null => false
    t.float    "amount",            :default => 0.0, :null => false
    t.integer  "donation_fund_id",  :default => 0,   :null => false
    t.string   "comment"
    t.integer  "customer_id",       :default => 0,   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "letter_sent"
    t.integer  "processed_by_id"
    t.integer  "purchasemethod_id", :default => 1,   :null => false
    t.string   "account_code"
  end

  create_table "options", :force => true do |t|
    t.string "grp"
    t.string "name"
    t.text   "value"
    t.text   "description"
    t.enum   "typ",         :limit => [:int, :string, :email, :float, :text], :default => :string, :null => false
  end

  create_table "purchasemethods", :force => true do |t|
    t.string  "description",               :default => "",        :null => false
    t.string  "shortdesc",   :limit => 10, :default => "?purch?", :null => false
    t.boolean "nonrevenue",                :default => false
  end

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "showdates", :force => true do |t|
    t.datetime "thedate"
    t.datetime "end_advance_sales"
    t.integer  "max_sales",         :default => 0, :null => false
    t.integer  "show_id",           :default => 0, :null => false
  end

  add_index "showdates", ["end_advance_sales"], :name => "end_advance_sales"

  create_table "shows", :force => true do |t|
    t.string   "name"
    t.date     "opening_date"
    t.date     "closing_date"
    t.integer  "house_capacity",   :limit => 2, :default => 0,            :null => false
    t.datetime "created_on",                                              :null => false
    t.text     "patron_notes"
    t.string   "landing_page_url"
    t.date     "listing_date",                  :default => '2009-11-29', :null => false
  end

  create_table "txn_types", :force => true do |t|
    t.string "desc",      :limit => 100, :default => "Other"
    t.string "shortdesc", :limit => 10,  :default => "???",   :null => false
  end

  create_table "txns", :force => true do |t|
    t.integer  "customer_id",       :default => 1,   :null => false
    t.integer  "entered_by_id",     :default => 1,   :null => false
    t.datetime "txn_date"
    t.integer  "txn_type_id",       :default => 0,   :null => false
    t.integer  "show_id"
    t.integer  "showdate_id"
    t.integer  "purchasemethod_id"
    t.integer  "voucher_id",        :default => 0,   :null => false
    t.float    "dollar_amount",     :default => 0.0, :null => false
    t.string   "comments"
  end

  create_table "valid_vouchers", :force => true do |t|
    t.integer  "showdate_id"
    t.integer  "vouchertype_id"
    t.string   "password"
    t.datetime "start_sales"
    t.datetime "end_sales"
    t.integer  "max_sales_for_type", :limit => 2, :default => 0, :null => false
  end

  add_index "valid_vouchers", ["showdate_id", "vouchertype_id"], :name => "index_valid_vouchers_on_showdate_id_and_vouchertype_id"
  add_index "valid_vouchers", ["start_sales"], :name => "index_valid_vouchers_on_start_sales"

  create_table "visits", :force => true do |t|
    t.datetime "updated_at"
    t.integer  "visited_by_id",                                                                                                                    :default => 0, :null => false
    t.enum     "contact_method",          :limit => [:Phone, :Email, :"Letter/Fax", :"In person"]
    t.string   "location"
    t.enum     "purpose",                 :limit => [:Preliminary, :Followup, :Presentation, :"Further Discussion", :Close, :Recognition, :Other]
    t.enum     "result",                  :limit => [:"No interest", :"Further cultivation", :"Arrange for Gift", :"Gift Received"]
    t.text     "additional_notes"
    t.date     "followup_date"
    t.string   "followup_action"
    t.integer  "next_ask_target",                                                                                                                  :default => 0, :null => false
    t.integer  "followup_assigned_to_id",                                                                                                          :default => 0, :null => false
    t.integer  "customer_id"
    t.date     "thedate",                                                                                                                                         :null => false
  end

  create_table "vouchers", :force => true do |t|
    t.integer  "vouchertype_id",                                                        :default => 0,                     :null => false
    t.integer  "customer_id",                                                           :default => 0,                     :null => false
    t.integer  "showdate_id",                                                           :default => 0,                     :null => false
    t.integer  "purchasemethod_id",                                                     :default => 0,                     :null => false
    t.string   "comments"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.boolean  "changeable",                                                            :default => true
    t.boolean  "fulfillment_needed",                                                    :default => false
    t.integer  "external_key",                                                          :default => 0
    t.boolean  "no_show",                                                               :default => false,                 :null => false
    t.string   "promo_code"
    t.integer  "processed_by_id"
    t.datetime "expiration_date",                                                       :default => '2008-12-31 00:00:00', :null => false
    t.datetime "sold_on"
    t.integer  "bundle_id",                                                             :default => 0,                     :null => false
    t.integer  "gift_purchaser_id",                                                     :default => 0,                     :null => false
    t.datetime "used"
    t.enum     "category",           :limit => [:revenue, :comp, :subscriber, :bundle]
  end

  add_index "vouchers", ["customer_id"], :name => "customer_id"

  create_table "vouchertypes", :force => true do |t|
    t.string   "name"
    t.float    "price",                                                                  :default => 0.0
    t.datetime "created_on"
    t.text     "comments"
    t.integer  "offer_public",                                                           :default => 0,                     :null => false
    t.boolean  "subscription"
    t.text     "included_vouchers"
    t.string   "promo_code",          :limit => 20,                                      :default => "",                    :null => false
    t.boolean  "walkup_sale_allowed",                                                    :default => true
    t.datetime "valid_date",                                                             :default => '2007-01-01 00:00:00', :null => false
    t.datetime "expiration_date",                                                        :default => '2008-01-01 00:00:00', :null => false
    t.boolean  "fulfillment_needed",                                                     :default => false
    t.string   "account_code",        :limit => 8,                                       :default => "",                    :null => false
    t.datetime "bundle_sales_start",                                                     :default => '2007-01-01 00:00:00', :null => false
    t.datetime "bundle_sales_end",                                                       :default => '2008-01-01 06:00:00', :null => false
    t.enum     "category",            :limit => [:revenue, :comp, :subscriber, :bundle]
  end

end
