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

ActiveRecord::Schema.define(version: 20190420212205) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_codes", force: :cascade do |t|
    t.string "name",            limit: 40,  default: "", null: false
    t.string "code",            limit: 255
    t.string "description",     limit: 255
    t.string "donation_prompt", limit: 255
  end

  create_table "customers", force: :cascade do |t|
    t.string   "first_name",                limit: 64,  default: "",                    null: false
    t.string   "last_name",                 limit: 64,  default: "",                    null: false
    t.string   "street",                    limit: 255
    t.string   "city",                      limit: 255
    t.string   "state",                     limit: 255
    t.string   "zip",                       limit: 255
    t.string   "day_phone",                 limit: 255
    t.string   "eve_phone",                 limit: 255
    t.string   "crypted_password",          limit: 255, default: ""
    t.string   "salt",                      limit: 40,  default: ""
    t.integer  "role",                                  default: 0,                     null: false
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.text     "comments"
    t.boolean  "blacklist",                             default: false,                 null: false
    t.datetime "last_login",                            default: '2007-04-06 15:40:20', null: false
    t.boolean  "e_blacklist",                           default: false,                 null: false
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
    t.string   "name",                      limit: 100, default: ""
    t.string   "remember_token",            limit: 40
    t.datetime "remember_token_expires_at"
    t.boolean  "created_by_admin"
    t.string   "tags",                      limit: 255
    t.boolean  "inactive"
    t.integer  "secret_question",                       default: 0,                     null: false
    t.string   "secret_answer",             limit: 255
    t.date     "birthday"
    t.string   "token"
    t.datetime "token_created_at"
  end

  create_table "customers_labels", id: false, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "label_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "type",              limit: 255
    t.integer  "number_of_records",             default: 0, null: false
    t.string   "filename",          limit: 255
    t.string   "content_type",      limit: 255
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.datetime "completed_at"
    t.integer  "show_id"
    t.integer  "showdate_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer  "vouchertype_id",                 default: 0,          null: false
    t.integer  "customer_id",                    default: 0,          null: false
    t.integer  "showdate_id"
    t.string   "comments",           limit: 255
    t.boolean  "fulfillment_needed",             default: false,      null: false
    t.string   "external_key",       limit: 255
    t.string   "promo_code",         limit: 255
    t.integer  "processed_by_id",                default: 2146722771, null: false
    t.integer  "bundle_id",                      default: 0,          null: false
    t.boolean  "checked_in",                     default: false,      null: false
    t.string   "category",           limit: 10
    t.boolean  "walkup",                         default: false,      null: false
    t.float    "amount",                         default: 0.0
    t.integer  "account_code_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "letter_sent"
    t.string   "type",               limit: 255
    t.integer  "order_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "options", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "advance_sales_cutoff",                                               default: 5
    t.integer  "sold_out_threshold",                                                 default: 90
    t.integer  "nearly_sold_out_threshold",                                          default: 80
    t.boolean  "allow_gift_tickets",                                                 default: false
    t.boolean  "allow_gift_subscriptions",                                           default: false
    t.integer  "season_start_month",                                                 default: 1
    t.integer  "season_start_day",                                                   default: 1
    t.integer  "cancel_grace_period",                                                default: 1440
    t.string   "default_donation_account_code",                          limit: 255
    t.string   "default_donation_account_code_with_subscriptions",       limit: 255
    t.string   "venue",                                                  limit: 255, default: "Enter Venue Name",                                           null: false
    t.string   "venue_address",                                          limit: 255, default: "Enter Venue Address",                                        null: false
    t.string   "venue_city_state_zip",                                   limit: 255, default: "Enter Venue City State Zip",                                 null: false
    t.string   "venue_telephone",                                        limit: 255, default: "Enter Venue Main Phone",                                     null: false
    t.string   "venue_homepage_url",                                     limit: 255
    t.string   "boxoffice_telephone",                                    limit: 255, default: "Enter Venue Box office phone",                               null: false
    t.string   "donation_ack_from",                                      limit: 255
    t.string   "boxoffice_daemon_notify",                                limit: 255
    t.string   "help_email",                                             limit: 255, default: ""
    t.integer  "send_birthday_reminders",                                            default: 0,                                                            null: false
    t.integer  "session_timeout",                                                    default: 1000,                                                         null: false
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
    t.string   "homepage_ticket_sales_text",                             limit: 255
    t.string   "homepage_subscription_sales_text",                       limit: 255
    t.boolean  "display_email_opt_out",                                              default: true
    t.string   "encourage_email_opt_in",                                 limit: 255
    t.text     "checkout_notices"
    t.text     "precheckout_popup"
    t.text     "subscription_purchase_email_notes"
    t.text     "general_confirmation_email_notes"
    t.text     "subscriber_confirmation_email_notes"
    t.text     "nonsubscriber_confirmation_email_notes"
    t.text     "terms_of_sale"
    t.string   "privacy_policy_url",                                     limit: 255, default: "Enter privacy policy page URL",                              null: false
    t.string   "mailchimp_default_list_name",                            limit: 255
    t.string   "default_retail_account_code",                            limit: 255
    t.string   "quick_donation_banner",                                  limit: 255, default: "Support us with a donation"
    t.string   "quick_donation_redirect",                                limit: 255
    t.text     "quick_donation_explanation"
    t.string   "class_sales_banner_for_current_subscribers",             limit: 255
    t.string   "class_sales_banner_for_nonsubscribers",                  limit: 255
    t.string   "class_sales_banner_for_next_season_subscribers",         limit: 255
    t.float    "subscription_order_service_charge",                                  default: 0.0
    t.string   "subscription_order_service_charge_description",          limit: 255
    t.integer  "subscription_order_service_charge_account_code",                     default: 0,                                                            null: false
    t.float    "regular_order_service_charge",                                       default: 0.0
    t.string   "regular_order_service_charge_description",               limit: 255
    t.integer  "regular_order_service_charge_account_code",                          default: 0,                                                            null: false
    t.float    "classes_order_service_charge",                                       default: 0.0
    t.string   "classes_order_service_charge_description",               limit: 255
    t.integer  "classes_order_service_charge_account_code",                          default: 0,                                                            null: false
    t.string   "special_seating_requests",                               limit: 255, default: " Please describe (electric wheelchair, walker, cane, etc.)", null: false
    t.integer  "limited_availability_threshold",                                     default: 40,                                                           null: false
    t.string   "stripe_key"
    t.string   "encrypted_stripe_secret"
    t.string   "encrypted_stripe_secret_iv"
    t.string   "encrypted_sendgrid_key_value"
    t.string   "encrypted_sendgrid_key_value_iv"
    t.string   "sendgrid_domain"
    t.string   "encrypted_mailchimp_key"
    t.string   "encrypted_mailchimp_key_iv"
    t.string   "stylesheet_url"
    t.boolean  "staff_access_only",                                                  default: false
    t.boolean  "allow_guest_checkout",                                               default: false
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "purchasemethod"
    t.integer  "processed_by_id"
    t.datetime "sold_on"
    t.integer  "purchaser_id"
    t.text     "valid_vouchers"
    t.text     "donation_data"
    t.string   "comments",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "walkup",                        default: false
    t.boolean  "ship_to_purchaser",             default: true
    t.string   "authorization",     limit: 255
    t.text     "retail_items"
    t.string   "external_key"
  end

  add_index "orders", ["external_key"], name: "index_orders_on_external_key", unique: true, using: :btree

  create_table "showdates", force: :cascade do |t|
    t.datetime "thedate"
    t.datetime "end_advance_sales"
    t.integer  "max_sales",                     default: 0, null: false
    t.integer  "show_id",                       default: 0, null: false
    t.string   "description",       limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "shows", force: :cascade do |t|
    t.string   "name",                      limit: 255
    t.date     "opening_date"
    t.date     "closing_date"
    t.integer  "house_capacity",            limit: 2,   default: 0,              null: false
    t.text     "patron_notes"
    t.string   "landing_page_url",          limit: 255
    t.date     "listing_date",                                                   null: false
    t.string   "description",               limit: 255
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.string   "event_type",                limit: 255, default: "Regular Show", null: false
    t.string   "sold_out_dropdown_message", limit: 255
    t.string   "sold_out_customer_info",    limit: 255
  end

  create_table "ticket_sales_imports", force: :cascade do |t|
    t.string   "vendor"
    t.text     "raw_data"
    t.integer  "processed_by_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "txns", force: :cascade do |t|
    t.integer  "customer_id",                default: 1,   null: false
    t.integer  "entered_by_id",              default: 1,   null: false
    t.datetime "txn_date"
    t.integer  "show_id"
    t.integer  "showdate_id"
    t.integer  "purchasemethod"
    t.integer  "voucher_id",                 default: 0,   null: false
    t.float    "dollar_amount",              default: 0.0, null: false
    t.string   "comments",       limit: 255
    t.integer  "order_id"
    t.string   "txn_type",       limit: 255
  end

  create_table "valid_vouchers", force: :cascade do |t|
    t.integer  "showdate_id"
    t.integer  "vouchertype_id"
    t.string   "promo_code",         limit: 255
    t.datetime "start_sales"
    t.datetime "end_sales"
    t.integer  "max_sales_for_type"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "vouchertypes", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.float    "price",                           default: 0.0
    t.datetime "created_at"
    t.text     "comments"
    t.integer  "offer_public",                    default: 0,     null: false
    t.boolean  "subscription"
    t.text     "included_vouchers"
    t.boolean  "walkup_sale_allowed",             default: false, null: false
    t.boolean  "fulfillment_needed",              default: false, null: false
    t.string   "category",            limit: 10
    t.integer  "season",                          default: 2011,  null: false
    t.boolean  "changeable",                      default: false, null: false
    t.integer  "account_code_id",                 default: 1,     null: false
    t.integer  "display_order",                   default: 0,     null: false
  end

end
