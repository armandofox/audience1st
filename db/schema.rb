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

ActiveRecord::Schema.define(:version => 20160316203603) do

  create_table "account_codes", :force => true do |t|
    t.string "name",        :limit => 40, :default => "", :null => false
    t.string "code"
    t.string "description"
  end

  create_table "bulk_downloads", :force => true do |t|
    t.string "vendor"
    t.string "username"
    t.string "password"
    t.string "type"
    t.text   "report_names"
  end

  create_table "customers", :force => true do |t|
    t.string   "first_name",                :limit => 64,         :default => "",                    :null => false
    t.string   "last_name",                 :limit => 64,         :default => "",                    :null => false
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "day_phone"
    t.string   "eve_phone"
    t.string   "crypted_password",                                :default => ""
    t.string   "salt",                      :limit => 40,         :default => ""
    t.integer  "role",                                            :default => 0,                     :null => false
    t.datetime "created_at",                                                                         :null => false
    t.datetime "updated_at",                                                                         :null => false
    t.text     "comments",                  :limit => 2147483647
    t.boolean  "blacklist",                                       :default => false,                 :null => false
    t.datetime "last_login",                                      :default => '2007-04-06 15:40:20', :null => false
    t.boolean  "e_blacklist",                                     :default => false,                 :null => false
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
    t.string   "email"
    t.string   "name",                      :limit => 100,        :default => ""
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.boolean  "created_by_admin"
    t.string   "tags"
    t.boolean  "inactive"
    t.integer  "secret_question",                                 :default => 0,                     :null => false
    t.string   "secret_answer"
    t.date     "birthday"
  end

  add_index "customers", ["city"], :name => "index_customers_on_city"
  add_index "customers", ["day_phone"], :name => "index_customers_on_day_phone"
  add_index "customers", ["email"], :name => "index_customers_on_email"
  add_index "customers", ["eve_phone"], :name => "index_customers_on_eve_phone"
  add_index "customers", ["first_name"], :name => "index_customers_on_first_name"
  add_index "customers", ["last_name"], :name => "index_customers_on_last_name"
  add_index "customers", ["role"], :name => "index_customers_on_role"
  add_index "customers", ["state"], :name => "index_customers_on_state"
  add_index "customers", ["street"], :name => "index_customers_on_street"
  add_index "customers", ["zip"], :name => "index_customers_on_zip"

  create_table "customers_labels", :id => false, :force => true do |t|
    t.integer "customer_id"
    t.integer "label_id"
  end

  add_index "customers_labels", ["customer_id"], :name => "index_customers_labels_on_customer_id"
  add_index "customers_labels", ["label_id"], :name => "index_customers_labels_on_label_id"

  create_table "imports", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.integer  "number_of_records", :default => 0, :null => false
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.datetime "completed_at"
    t.integer  "show_id"
    t.integer  "showdate_id"
  end

  create_table "items", :force => true do |t|
    t.integer  "vouchertype_id",                                                                    :default => 0,          :null => false
    t.integer  "customer_id",                                                                       :default => 0,          :null => false
    t.integer  "showdate_id"
    t.string   "comments"
    t.boolean  "fulfillment_needed",                                                                :default => false,      :null => false
    t.string   "external_key"
    t.string   "promo_code"
    t.integer  "processed_by_id",                                                                   :default => 2146722771, :null => false
    t.integer  "bundle_id",                                                                         :default => 0,          :null => false
    t.boolean  "checked_in",                                                                        :default => false,      :null => false
    t.enum     "category",           :limit => [:revenue, :comp, :subscriber, :bundle, :nonticket]
    t.boolean  "walkup",                                                                            :default => false,      :null => false
    t.float    "amount",                                                                            :default => 0.0
    t.integer  "account_code_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "letter_sent"
    t.string   "type"
    t.integer  "order_id"
  end

  add_index "items", ["account_code_id"], :name => "index_items_on_account_code_id"
  add_index "items", ["bundle_id"], :name => "index_items_on_bundle_id"
  add_index "items", ["customer_id"], :name => "customer_id"
  add_index "items", ["order_id"], :name => "index_items_on_order_id"
  add_index "items", ["showdate_id"], :name => "index_vouchers_on_showdate_id"
  add_index "items", ["type"], :name => "index_items_on_type"
  add_index "items", ["vouchertype_id"], :name => "index_items_on_vouchertype_id"

  create_table "labels", :force => true do |t|
    t.string "name"
  end

  create_table "options", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "venue_id"
    t.string   "venue_shortname"
    t.integer  "advance_sales_cutoff",                                   :default => 5
    t.integer  "sold_out_threshold",                                     :default => 90
    t.integer  "nearly_sold_out_threshold",                              :default => 80
    t.boolean  "allow_gift_tickets",                                     :default => false
    t.boolean  "allow_gift_subscriptions",                               :default => false
    t.integer  "season_start_month",                                     :default => 1
    t.integer  "season_start_day",                                       :default => 1
    t.integer  "cancel_grace_period",                                    :default => 1440
    t.string   "default_donation_account_code"
    t.string   "default_donation_account_code_with_subscriptions"
    t.string   "venue",                                                  :default => "Enter Venue Name",                                           :null => false
    t.string   "venue_address",                                          :default => "Enter Venue Address",                                        :null => false
    t.string   "venue_city_state_zip",                                   :default => "Enter Venue City State Zip",                                 :null => false
    t.string   "venue_telephone",                                        :default => "Enter Venue Main Phone",                                     :null => false
    t.string   "venue_homepage_url"
    t.string   "boxoffice_telephone",                                    :default => "Enter Venue Box office phone",                               :null => false
    t.string   "donation_ack_from"
    t.string   "boxoffice_daemon_notify"
    t.string   "help_email",                                             :default => "Enter Help Email",                                           :null => false
    t.integer  "send_birthday_reminders",                                :default => 0,                                                            :null => false
    t.integer  "session_timeout",                                        :default => 1000,                                                         :null => false
    t.text     "welcome_page_subscriber_message"
    t.text     "welcome_page_nonsubscriber_message"
    t.text     "special_event_sales_banner_for_current_subscribers"
    t.text     "special_event_sales_banner_for_next_season_subscribers"
    t.text     "special_event_sales_banner_for_nonsubscribers"
    t.text     "subscription_sales_banner_for_current_subscribers"
    t.text     "subscription_sales_banner_for_next_season_subscribers"
    t.text     "subscription_sales_banner_for_nonsubscribers"
    t.text     "regular_show_sales_banner_for_current_subscribers"
    t.text     "regular_show_sales_banner_for_next_season_subscribers"
    t.text     "regular_show_sales_banner_for_nonsubscribers"
    t.text     "top_level_banner_text"
    t.string   "homepage_ticket_sales_text"
    t.string   "homepage_subscription_sales_text"
    t.boolean  "display_email_opt_out",                                  :default => true
    t.string   "encourage_email_opt_in"
    t.text     "checkout_notices"
    t.text     "precheckout_popup"
    t.text     "subscription_purchase_email_notes"
    t.text     "general_confirmation_email_notes"
    t.text     "subscriber_confirmation_email_notes"
    t.text     "nonsubscriber_confirmation_email_notes"
    t.text     "terms_of_sale"
    t.string   "privacy_policy_url",                                     :default => "Enter privacy policy page URL",                              :null => false
    t.string   "mailchimp_default_list_name"
    t.string   "default_retail_account_code"
    t.string   "quick_donation_banner",                                  :default => "Support us with a donation"
    t.string   "quick_donation_redirect"
    t.text     "quick_donation_explanation"
    t.string   "class_sales_banner_for_current_subscribers"
    t.string   "class_sales_banner_for_nonsubscribers"
    t.string   "class_sales_banner_for_next_season_subscribers"
    t.float    "subscription_order_service_charge",                      :default => 0.0
    t.string   "subscription_order_service_charge_description"
    t.integer  "subscription_order_service_charge_account_code",         :default => 0,                                                            :null => false
    t.float    "regular_order_service_charge",                           :default => 0.0
    t.string   "regular_order_service_charge_description"
    t.integer  "regular_order_service_charge_account_code",              :default => 0,                                                            :null => false
    t.float    "classes_order_service_charge",                           :default => 0.0
    t.string   "classes_order_service_charge_description"
    t.integer  "classes_order_service_charge_account_code",              :default => 0,                                                            :null => false
    t.string   "special_seating_requests",                               :default => " Please describe (electric wheelchair, walker, cane, etc.)", :null => false
    t.integer  "limited_availability_threshold",                         :default => 40,                                                           :null => false
  end

  create_table "orders", :force => true do |t|
    t.string   "authorization"
    t.integer  "customer_id"
    t.integer  "purchasemethod_id"
    t.integer  "processed_by_id"
    t.datetime "sold_on"
    t.integer  "purchaser_id"
    t.text     "valid_vouchers"
    t.text     "donation_data"
    t.string   "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "walkup",            :default => false
    t.boolean  "ship_to_purchaser", :default => true
    t.text     "retail_items"
  end

  add_index "orders", ["authorization"], :name => "index_orders_on_authorization"
  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["purchaser_id"], :name => "index_orders_on_purchaser_id"
  add_index "orders", ["walkup"], :name => "index_orders_on_walkup"

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
    t.text     "data",       :limit => 2147483647
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "showdates", :force => true do |t|
    t.datetime "thedate"
    t.datetime "end_advance_sales"
    t.integer  "max_sales",         :default => 0, :null => false
    t.integer  "show_id",           :default => 0, :null => false
    t.string   "description"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "showdates", ["end_advance_sales"], :name => "end_advance_sales"
  add_index "showdates", ["show_id"], :name => "index_showdates_on_show_id"

  create_table "shows", :force => true do |t|
    t.string   "name"
    t.date     "opening_date"
    t.date     "closing_date"
    t.integer  "house_capacity",            :limit => 2, :default => 0,              :null => false
    t.text     "patron_notes"
    t.string   "landing_page_url"
    t.date     "listing_date",                                                       :null => false
    t.string   "description"
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.string   "event_type",                             :default => "Regular Show", :null => false
    t.string   "sold_out_dropdown_message"
    t.string   "sold_out_customer_info"
  end

  create_table "txns", :force => true do |t|
    t.integer  "customer_id",       :default => 1,   :null => false
    t.integer  "entered_by_id",     :default => 1,   :null => false
    t.datetime "txn_date"
    t.integer  "show_id"
    t.integer  "showdate_id"
    t.integer  "purchasemethod_id"
    t.integer  "voucher_id",        :default => 0,   :null => false
    t.float    "dollar_amount",     :default => 0.0, :null => false
    t.string   "comments"
    t.integer  "order_id"
    t.string   "txn_type"
  end

  add_index "txns", ["customer_id"], :name => "index_txns_on_customer_id"

  create_table "valid_vouchers", :force => true do |t|
    t.integer  "showdate_id"
    t.integer  "vouchertype_id"
    t.string   "promo_code"
    t.datetime "start_sales"
    t.datetime "end_sales"
    t.integer  "max_sales_for_type"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "valid_vouchers", ["showdate_id", "vouchertype_id"], :name => "index_valid_vouchers_on_showdate_id_and_vouchertype_id"
  add_index "valid_vouchers", ["showdate_id"], :name => "index_valid_vouchers_on_showdate_id"
  add_index "valid_vouchers", ["start_sales"], :name => "index_valid_vouchers_on_start_sales"
  add_index "valid_vouchers", ["vouchertype_id"], :name => "index_valid_vouchers_on_vouchertype_id"

  create_table "vouchertypes", :force => true do |t|
    t.string   "name"
    t.float    "price",                                                                              :default => 0.0
    t.datetime "created_at"
    t.text     "comments"
    t.integer  "offer_public",                                                                       :default => 0,     :null => false
    t.boolean  "subscription"
    t.text     "included_vouchers"
    t.boolean  "walkup_sale_allowed",                                                                :default => false, :null => false
    t.boolean  "fulfillment_needed",                                                                 :default => false, :null => false
    t.enum     "category",            :limit => [:revenue, :comp, :subscriber, :bundle, :nonticket]
    t.integer  "season",                                                                             :default => 2011,  :null => false
    t.boolean  "changeable",                                                                         :default => false, :null => false
    t.integer  "account_code_id",                                                                    :default => 1,     :null => false
    t.integer  "display_order",                                                                      :default => 0,     :null => false
  end

  add_index "vouchertypes", ["category", "season"], :name => "index_vouchertypes_on_category_and_season"
  add_index "vouchertypes", ["category"], :name => "index_vouchertypes_on_category"
  add_index "vouchertypes", ["season"], :name => "index_vouchertypes_on_season"
  add_index "vouchertypes", ["subscription"], :name => "index_vouchertypes_on_subscription"
  add_index "vouchertypes", ["walkup_sale_allowed"], :name => "index_vouchertypes_on_walkup_sale_allowed"

end
