# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170628202024) do

  create_table "account_codes", force: :cascade do |t|
    t.string "name",        limit: 40,  default: "", null: false
    t.string "code",        limit: 255
    t.string "description", limit: 255
  end

  create_table "bulk_downloads", force: :cascade do |t|
    t.string "vendor",       limit: 255
    t.string "username",     limit: 255
    t.string "password",     limit: 255
    t.string "type",         limit: 255
    t.text   "report_names", limit: 65535
  end

  create_table "customers", force: :cascade do |t|
    t.string   "first_name",                limit: 64,         default: "",                    null: false
    t.string   "last_name",                 limit: 64,         default: "",                    null: false
    t.string   "street",                    limit: 255
    t.string   "city",                      limit: 255
    t.string   "state",                     limit: 255
    t.string   "zip",                       limit: 255
    t.string   "day_phone",                 limit: 255
    t.string   "eve_phone",                 limit: 255
    t.string   "crypted_password",          limit: 255,        default: ""
    t.string   "salt",                      limit: 40,         default: ""
    t.integer  "role",                      limit: 4,          default: 0,                     null: false
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.text     "comments",                  limit: 4294967295
    t.boolean  "blacklist",                                    default: false,                 null: false
    t.datetime "last_login",                                   default: '2007-04-06 15:40:20', null: false
    t.boolean  "e_blacklist",                                  default: false,                 null: false
    t.string   "company",                   limit: 255
    t.string   "title",                     limit: 255
    t.string   "company_address_line_1",    limit: 255
    t.string   "company_address_line_2",    limit: 255
    t.string   "company_city",              limit: 255
    t.string   "company_state",             limit: 255
    t.string   "company_zip",               limit: 255
    t.string   "work_phone",                limit: 255
    t.string   "cell_phone",                limit: 255
    t.string   "work_fax",                  limit: 255
    t.string   "company_url",               limit: 255
    t.string   "best_way_to_contact",       limit: 255
    t.string   "email",                     limit: 255
    t.string   "name",                      limit: 100,        default: ""
    t.string   "remember_token",            limit: 40
    t.datetime "remember_token_expires_at"
    t.boolean  "created_by_admin"
    t.string   "tags",                      limit: 255
    t.boolean  "inactive"
    t.integer  "secret_question",           limit: 4,          default: 0,                     null: false
    t.string   "secret_answer",             limit: 255
    t.date     "birthday"
  end

  add_index "customers", ["city"], name: "index_customers_on_city", using: :btree
  add_index "customers", ["day_phone"], name: "index_customers_on_day_phone", using: :btree
  add_index "customers", ["email"], name: "index_customers_on_email", using: :btree
  add_index "customers", ["eve_phone"], name: "index_customers_on_eve_phone", using: :btree
  add_index "customers", ["first_name"], name: "index_customers_on_first_name", using: :btree
  add_index "customers", ["last_name"], name: "index_customers_on_last_name", using: :btree
  add_index "customers", ["role"], name: "index_customers_on_role", using: :btree
  add_index "customers", ["state"], name: "index_customers_on_state", using: :btree
  add_index "customers", ["street"], name: "index_customers_on_street", using: :btree
  add_index "customers", ["zip"], name: "index_customers_on_zip", using: :btree

  create_table "customers_labels", id: false, force: :cascade do |t|
    t.integer "customer_id", limit: 4
    t.integer "label_id",    limit: 4
  end

  add_index "customers_labels", ["customer_id"], name: "index_customers_labels_on_customer_id", using: :btree
  add_index "customers_labels", ["label_id"], name: "index_customers_labels_on_label_id", using: :btree

  create_table "imports", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "type",              limit: 255
    t.integer  "number_of_records", limit: 4,   default: 0, null: false
    t.string   "filename",          limit: 255
    t.string   "content_type",      limit: 255
    t.integer  "size",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id",       limit: 4
    t.datetime "completed_at"
    t.integer  "show_id",           limit: 4
    t.integer  "showdate_id",       limit: 4
  end

  create_table "items", force: :cascade do |t|
    t.integer  "vouchertype_id",     limit: 4,   default: 0,          null: false
    t.integer  "customer_id",        limit: 4,   default: 0,          null: false
    t.integer  "showdate_id",        limit: 4
    t.string   "comments",           limit: 255
    t.boolean  "fulfillment_needed",             default: false,      null: false
    t.string   "external_key",       limit: 255
    t.string   "promo_code",         limit: 255
    t.integer  "processed_by_id",    limit: 4,   default: 2146722771, null: false
    t.integer  "bundle_id",          limit: 4,   default: 0,          null: false
    t.boolean  "checked_in",                     default: false,      null: false
    t.string   "category",           limit: 10
    t.boolean  "walkup",                         default: false,      null: false
    t.float    "amount",             limit: 24,  default: 0.0
    t.integer  "account_code_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "letter_sent"
    t.string   "type",               limit: 255
    t.integer  "order_id",           limit: 4
  end

  add_index "items", ["account_code_id"], name: "index_items_on_account_code_id", using: :btree
  add_index "items", ["bundle_id"], name: "index_items_on_bundle_id", using: :btree
  add_index "items", ["customer_id"], name: "customer_id", using: :btree
  add_index "items", ["order_id"], name: "index_items_on_order_id", using: :btree
  add_index "items", ["showdate_id"], name: "index_vouchers_on_showdate_id", using: :btree
  add_index "items", ["type"], name: "index_items_on_type", using: :btree
  add_index "items", ["vouchertype_id"], name: "index_items_on_vouchertype_id", using: :btree

  create_table "labels", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "options", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "venue_id",                                               limit: 4
    t.string   "venue_shortname",                                        limit: 255
    t.integer  "advance_sales_cutoff",                                   limit: 4,     default: 5
    t.integer  "sold_out_threshold",                                     limit: 4,     default: 90
    t.integer  "nearly_sold_out_threshold",                              limit: 4,     default: 80
    t.boolean  "allow_gift_tickets",                                                   default: false
    t.boolean  "allow_gift_subscriptions",                                             default: false
    t.integer  "season_start_month",                                     limit: 4,     default: 1
    t.integer  "season_start_day",                                       limit: 4,     default: 1
    t.integer  "cancel_grace_period",                                    limit: 4,     default: 1440
    t.string   "default_donation_account_code",                          limit: 255
    t.string   "default_donation_account_code_with_subscriptions",       limit: 255
    t.string   "venue",                                                  limit: 255,   default: "Enter Venue Name",                                           null: false
    t.string   "venue_address",                                          limit: 255,   default: "Enter Venue Address",                                        null: false
    t.string   "venue_city_state_zip",                                   limit: 255,   default: "Enter Venue City State Zip",                                 null: false
    t.string   "venue_telephone",                                        limit: 255,   default: "Enter Venue Main Phone",                                     null: false
    t.string   "venue_homepage_url",                                     limit: 255
    t.string   "boxoffice_telephone",                                    limit: 255,   default: "Enter Venue Box office phone",                               null: false
    t.string   "donation_ack_from",                                      limit: 255
    t.string   "boxoffice_daemon_notify",                                limit: 255
    t.string   "help_email",                                             limit: 255,   default: ""
    t.integer  "send_birthday_reminders",                                limit: 4,     default: 0,                                                            null: false
    t.integer  "session_timeout",                                        limit: 4,     default: 1000,                                                         null: false
    t.text     "welcome_page_subscriber_message",                        limit: 65535
    t.text     "welcome_page_nonsubscriber_message",                     limit: 65535
    t.text     "special_event_sales_banner_for_current_subscribers",     limit: 65535
    t.text     "special_event_sales_banner_for_next_season_subscribers", limit: 65535
    t.text     "special_event_sales_banner_for_nonsubscribers",          limit: 65535
    t.text     "subscription_sales_banner_for_current_subscribers",      limit: 65535
    t.text     "subscription_sales_banner_for_next_season_subscribers",  limit: 65535
    t.text     "subscription_sales_banner_for_nonsubscribers",           limit: 65535
    t.text     "regular_show_sales_banner_for_current_subscribers",      limit: 65535
    t.text     "regular_show_sales_banner_for_next_season_subscribers",  limit: 65535
    t.text     "regular_show_sales_banner_for_nonsubscribers",           limit: 65535
    t.text     "top_level_banner_text",                                  limit: 65535
    t.string   "homepage_ticket_sales_text",                             limit: 255
    t.string   "homepage_subscription_sales_text",                       limit: 255
    t.boolean  "display_email_opt_out",                                                default: true
    t.string   "encourage_email_opt_in",                                 limit: 255
    t.text     "checkout_notices",                                       limit: 65535
    t.text     "precheckout_popup",                                      limit: 65535
    t.text     "subscription_purchase_email_notes",                      limit: 65535
    t.text     "general_confirmation_email_notes",                       limit: 65535
    t.text     "subscriber_confirmation_email_notes",                    limit: 65535
    t.text     "nonsubscriber_confirmation_email_notes",                 limit: 65535
    t.text     "terms_of_sale",                                          limit: 65535
    t.string   "privacy_policy_url",                                     limit: 255,   default: "Enter privacy policy page URL",                              null: false
    t.string   "mailchimp_default_list_name",                            limit: 255
    t.string   "default_retail_account_code",                            limit: 255
    t.string   "quick_donation_banner",                                  limit: 255,   default: "Support us with a donation"
    t.string   "quick_donation_redirect",                                limit: 255
    t.text     "quick_donation_explanation",                             limit: 65535
    t.string   "class_sales_banner_for_current_subscribers",             limit: 255
    t.string   "class_sales_banner_for_nonsubscribers",                  limit: 255
    t.string   "class_sales_banner_for_next_season_subscribers",         limit: 255
    t.float    "subscription_order_service_charge",                      limit: 24,    default: 0.0
    t.string   "subscription_order_service_charge_description",          limit: 255
    t.integer  "subscription_order_service_charge_account_code",         limit: 4,     default: 0,                                                            null: false
    t.float    "regular_order_service_charge",                           limit: 24,    default: 0.0
    t.string   "regular_order_service_charge_description",               limit: 255
    t.integer  "regular_order_service_charge_account_code",              limit: 4,     default: 0,                                                            null: false
    t.float    "classes_order_service_charge",                           limit: 24,    default: 0.0
    t.string   "classes_order_service_charge_description",               limit: 255
    t.integer  "classes_order_service_charge_account_code",              limit: 4,     default: 0,                                                            null: false
    t.string   "special_seating_requests",                               limit: 255,   default: " Please describe (electric wheelchair, walker, cane, etc.)", null: false
    t.integer  "limited_availability_threshold",                         limit: 4,     default: 40,                                                           null: false
  end

  create_table "orders", force: :cascade do |t|
    t.string   "authorization",     limit: 255
    t.integer  "customer_id",       limit: 4
    t.integer  "purchasemethod_id", limit: 4
    t.integer  "processed_by_id",   limit: 4
    t.datetime "sold_on"
    t.integer  "purchaser_id",      limit: 4
    t.text     "valid_vouchers",    limit: 65535
    t.text     "donation_data",     limit: 65535
    t.string   "comments",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "walkup",                          default: false
    t.boolean  "ship_to_purchaser",               default: true
    t.text     "retail_items",      limit: 65535
  end

  add_index "orders", ["authorization"], name: "index_orders_on_authorization", using: :btree
  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["purchaser_id"], name: "index_orders_on_purchaser_id", using: :btree
  add_index "orders", ["walkup"], name: "index_orders_on_walkup", using: :btree

  create_table "purchasemethods", force: :cascade do |t|
    t.string  "description", limit: 255, default: "",        null: false
    t.string  "shortdesc",   limit: 10,  default: "?purch?", null: false
    t.boolean "nonrevenue",              default: false
  end

  create_table "schema_info", id: false, force: :cascade do |t|
    t.integer "version", limit: 4
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255
    t.text     "data",       limit: 4294967295
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "sessions_session_id_index", using: :btree

  create_table "showdates", force: :cascade do |t|
    t.datetime "thedate"
    t.datetime "end_advance_sales"
    t.integer  "max_sales",         limit: 4,   default: 0, null: false
    t.integer  "show_id",           limit: 4,   default: 0, null: false
    t.string   "description",       limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "showdates", ["end_advance_sales"], name: "end_advance_sales", using: :btree
  add_index "showdates", ["show_id"], name: "index_showdates_on_show_id", using: :btree

  create_table "shows", force: :cascade do |t|
    t.string   "name",                      limit: 255
    t.date     "opening_date"
    t.date     "closing_date"
    t.integer  "house_capacity",            limit: 2,     default: 0,              null: false
    t.text     "patron_notes",              limit: 65535
    t.string   "landing_page_url",          limit: 255
    t.date     "listing_date",                                                     null: false
    t.string   "description",               limit: 255
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.string   "event_type",                limit: 255,   default: "Regular Show", null: false
    t.string   "sold_out_dropdown_message", limit: 255
    t.string   "sold_out_customer_info",    limit: 255
  end

  create_table "txns", force: :cascade do |t|
    t.integer  "customer_id",       limit: 4,   default: 1,   null: false
    t.integer  "entered_by_id",     limit: 4,   default: 1,   null: false
    t.datetime "txn_date"
    t.integer  "show_id",           limit: 4
    t.integer  "showdate_id",       limit: 4
    t.integer  "purchasemethod_id", limit: 4
    t.integer  "voucher_id",        limit: 4,   default: 0,   null: false
    t.float    "dollar_amount",     limit: 24,  default: 0.0, null: false
    t.string   "comments",          limit: 255
    t.integer  "order_id",          limit: 4
    t.string   "txn_type",          limit: 255
  end

  add_index "txns", ["customer_id"], name: "index_txns_on_customer_id", using: :btree

  create_table "valid_vouchers", force: :cascade do |t|
    t.integer  "showdate_id",        limit: 4
    t.integer  "vouchertype_id",     limit: 4
    t.string   "promo_code",         limit: 255
    t.datetime "start_sales"
    t.datetime "end_sales"
    t.integer  "max_sales_for_type", limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "valid_vouchers", ["showdate_id", "vouchertype_id"], name: "index_valid_vouchers_on_showdate_id_and_vouchertype_id", using: :btree
  add_index "valid_vouchers", ["showdate_id"], name: "index_valid_vouchers_on_showdate_id", using: :btree
  add_index "valid_vouchers", ["start_sales"], name: "index_valid_vouchers_on_start_sales", using: :btree
  add_index "valid_vouchers", ["vouchertype_id"], name: "index_valid_vouchers_on_vouchertype_id", using: :btree

  create_table "vouchertypes", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.float    "price",               limit: 24,    default: 0.0
    t.datetime "created_at"
    t.text     "comments",            limit: 65535
    t.integer  "offer_public",        limit: 4,     default: 0,     null: false
    t.boolean  "subscription"
    t.text     "included_vouchers",   limit: 65535
    t.boolean  "walkup_sale_allowed",               default: false, null: false
    t.boolean  "fulfillment_needed",                default: false, null: false
    t.string   "category",            limit: 10
    t.integer  "season",              limit: 4,     default: 2011,  null: false
    t.boolean  "changeable",                        default: false, null: false
    t.integer  "account_code_id",     limit: 4,     default: 1,     null: false
    t.integer  "display_order",       limit: 4,     default: 0,     null: false
  end

  add_index "vouchertypes", ["category", "season"], name: "index_vouchertypes_on_category_and_season", using: :btree
  add_index "vouchertypes", ["category"], name: "index_vouchertypes_on_category", using: :btree
  add_index "vouchertypes", ["season"], name: "index_vouchertypes_on_season", using: :btree
  add_index "vouchertypes", ["subscription"], name: "index_vouchertypes_on_subscription", using: :btree
  add_index "vouchertypes", ["walkup_sale_allowed"], name: "index_vouchertypes_on_walkup_sale_allowed", using: :btree

end
