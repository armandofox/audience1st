# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_09_27_062746) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "account_codes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, default: "", null: false
    t.string "code", limit: 255
    t.string "description", limit: 255
    t.string "donation_prompt", limit: 255
  end

  create_table "customers", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 64, default: "", null: false
    t.string "last_name", limit: 64, default: "", null: false
    t.string "street", limit: 255
    t.string "city", limit: 255
    t.string "state", limit: 255
    t.string "zip", limit: 255
    t.string "day_phone", limit: 255
    t.string "eve_phone", limit: 255
    t.string "crypted_password", limit: 255, default: ""
    t.string "salt", limit: 40, default: ""
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comments"
    t.boolean "blacklist", default: false, null: false
    t.datetime "last_login", default: "2007-04-06 15:40:20", null: false
    t.boolean "e_blacklist", default: false, null: false
    t.string "company", limit: 255
    t.string "title", limit: 255
    t.string "company_address_line_1", limit: 255
    t.string "company_address_line_2", limit: 255
    t.string "company_city", limit: 255
    t.string "company_state", limit: 255
    t.string "company_zip", limit: 255
    t.string "work_phone", limit: 255
    t.string "cell_phone", limit: 255
    t.string "work_fax", limit: 255
    t.string "company_url", limit: 255
    t.string "best_way_to_contact", limit: 255
    t.string "email", limit: 255
    t.string "name", limit: 100, default: ""
    t.string "remember_token", limit: 40
    t.datetime "remember_token_expires_at"
    t.boolean "created_by_admin"
    t.string "tags", limit: 255
    t.boolean "inactive"
    t.integer "secret_question", default: 0, null: false
    t.string "secret_answer", limit: 255
    t.date "birthday"
    t.string "token"
    t.datetime "token_created_at"
    t.integer "ticket_sales_import_id"
    t.index ["city"], name: "index_customers_on_city"
    t.index ["city"], name: "public_customers_city4_idx"
    t.index ["day_phone"], name: "index_customers_on_day_phone"
    t.index ["day_phone"], name: "public_customers_day_phone7_idx"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["email"], name: "public_customers_email2_idx"
    t.index ["eve_phone"], name: "index_customers_on_eve_phone"
    t.index ["eve_phone"], name: "public_customers_eve_phone8_idx"
    t.index ["first_name"], name: "index_customers_on_first_name"
    t.index ["first_name"], name: "public_customers_first_name1_idx"
    t.index ["last_name"], name: "index_customers_on_last_name"
    t.index ["last_name"], name: "public_customers_last_name0_idx"
    t.index ["role"], name: "index_customers_on_role"
    t.index ["role"], name: "public_customers_role9_idx"
    t.index ["state"], name: "index_customers_on_state"
    t.index ["state"], name: "public_customers_state5_idx"
    t.index ["street"], name: "index_customers_on_street"
    t.index ["street"], name: "public_customers_street3_idx"
    t.index ["ticket_sales_import_id"], name: "index_customers_on_ticket_sales_import_id"
    t.index ["zip"], name: "index_customers_on_zip"
    t.index ["zip"], name: "public_customers_zip6_idx"
  end

  create_table "customers_labels", id: false, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "label_id"
    t.index ["customer_id", "label_id"], name: "index_customers_labels_on_customer_id_and_label_id"
    t.index ["customer_id"], name: "index_customers_labels_on_customer_id"
    t.index ["customer_id"], name: "public_customers_labels_customer_id0_idx"
    t.index ["label_id"], name: "index_customers_labels_on_label_id"
    t.index ["label_id"], name: "public_customers_labels_label_id1_idx"
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.integer "vouchertype_id", default: 0, null: false
    t.integer "customer_id", default: 0, null: false
    t.integer "showdate_id"
    t.string "comments", limit: 255
    t.boolean "fulfillment_needed", default: false, null: false
    t.string "promo_code", limit: 255
    t.integer "processed_by_id", default: 2146722771, null: false
    t.integer "bundle_id", default: 0, null: false
    t.boolean "checked_in", default: false, null: false
    t.boolean "walkup", default: false, null: false
    t.float "amount", default: 0.0
    t.integer "account_code_id"
    t.datetime "updated_at"
    t.datetime "letter_sent"
    t.string "type", limit: 255
    t.integer "order_id"
    t.boolean "finalized"
    t.string "seat"
    t.datetime "sold_on"
    t.integer "recurring_donation_id"
    t.string "state"
    t.index ["account_code_id"], name: "index_items_on_account_code_id"
    t.index ["account_code_id"], name: "public_items_account_code_id6_idx"
    t.index ["bundle_id"], name: "index_items_on_bundle_id"
    t.index ["bundle_id"], name: "public_items_bundle_id4_idx"
    t.index ["customer_id"], name: "customer_id"
    t.index ["customer_id"], name: "index_items_on_customer_id"
    t.index ["customer_id"], name: "public_items_customer_id0_idx"
    t.index ["finalized"], name: "index_items_on_finalized"
    t.index ["order_id"], name: "index_items_on_order_id"
    t.index ["order_id"], name: "public_items_order_id3_idx"
    t.index ["processed_by_id"], name: "index_items_on_processed_by_id"
    t.index ["seat"], name: "index_items_on_seat"
    t.index ["showdate_id"], name: "index_items_on_showdate_id"
    t.index ["showdate_id"], name: "index_vouchers_on_showdate_id"
    t.index ["showdate_id"], name: "public_items_showdate_id1_idx"
    t.index ["type"], name: "index_items_on_type"
    t.index ["type"], name: "public_items_type2_idx"
    t.index ["vouchertype_id"], name: "index_items_on_vouchertype_id"
    t.index ["vouchertype_id"], name: "public_items_vouchertype_id5_idx"
  end

  create_table "labels", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "advance_sales_cutoff", default: 5
    t.integer "nearly_sold_out_threshold", default: 80
    t.boolean "allow_gift_tickets", default: false
    t.boolean "allow_gift_subscriptions", default: false
    t.integer "season_start_month", default: 1
    t.integer "season_start_day", default: 1
    t.integer "cancel_grace_period", default: 1440
    t.string "default_donation_account_code", limit: 255
    t.string "default_donation_account_code_with_subscriptions", limit: 255
    t.string "venue", limit: 255, default: "Enter Venue Name", null: false
    t.string "venue_address", limit: 255, default: "Enter Venue Address", null: false
    t.string "venue_city_state_zip", limit: 255, default: "Enter Venue City State Zip", null: false
    t.string "venue_telephone", limit: 255, default: "Enter Venue Main Phone", null: false
    t.string "venue_homepage_url", limit: 255
    t.string "boxoffice_telephone", limit: 255, default: "Enter Venue Box office phone", null: false
    t.string "donation_ack_from", limit: 255
    t.string "box_office_email", limit: 255
    t.string "help_email", limit: 255, default: ""
    t.integer "send_birthday_reminders", default: 0, null: false
    t.integer "session_timeout", default: 1000, null: false
    t.text "welcome_page_subscriber_message"
    t.text "welcome_page_nonsubscriber_message"
    t.text "special_event_sales_banner_for_current_subscribers"
    t.text "special_event_sales_banner_for_next_season_subscribers"
    t.text "special_event_sales_banner_for_nonsubscribers"
    t.text "subscription_sales_banner_for_current_subscribers"
    t.text "subscription_sales_banner_for_next_season_subscribers"
    t.text "subscription_sales_banner_for_nonsubscribers"
    t.text "regular_show_sales_banner_for_current_subscribers"
    t.text "regular_show_sales_banner_for_next_season_subscribers"
    t.text "regular_show_sales_banner_for_nonsubscribers"
    t.text "top_level_banner_text"
    t.string "homepage_ticket_sales_text", limit: 255
    t.string "homepage_subscription_sales_text", limit: 255
    t.boolean "display_email_opt_out", default: true
    t.string "encourage_email_opt_in", limit: 255
    t.text "checkout_notices"
    t.text "precheckout_popup"
    t.text "subscription_purchase_email_notes"
    t.text "general_confirmation_email_notes"
    t.text "subscriber_confirmation_email_notes"
    t.text "nonsubscriber_confirmation_email_notes"
    t.text "terms_of_sale"
    t.string "privacy_policy_url", limit: 255, default: "Enter privacy policy page URL", null: false
    t.string "mailchimp_default_list_name", limit: 255
    t.string "default_retail_account_code", limit: 255
    t.string "quick_donation_banner", limit: 255, default: "Support us with a donation"
    t.string "quick_donation_redirect", limit: 255
    t.text "quick_donation_explanation"
    t.string "class_sales_banner_for_current_subscribers", limit: 255
    t.string "class_sales_banner_for_nonsubscribers", limit: 255
    t.string "class_sales_banner_for_next_season_subscribers", limit: 255
    t.float "subscription_order_service_charge", default: 0.0
    t.string "subscription_order_service_charge_description", limit: 255
    t.integer "subscription_order_service_charge_account_code", default: 0, null: false
    t.float "regular_order_service_charge", default: 0.0
    t.string "regular_order_service_charge_description", limit: 255
    t.integer "regular_order_service_charge_account_code", default: 0, null: false
    t.float "classes_order_service_charge", default: 0.0
    t.string "classes_order_service_charge_description", limit: 255
    t.integer "classes_order_service_charge_account_code", default: 0, null: false
    t.string "special_seating_requests", limit: 255, default: " Please describe (electric wheelchair, walker, cane, etc.)", null: false
    t.integer "limited_availability_threshold", default: 40, null: false
    t.string "stripe_key"
    t.string "encrypted_stripe_secret"
    t.string "encrypted_stripe_secret_iv"
    t.string "sender_domain"
    t.string "encrypted_mailchimp_key"
    t.string "encrypted_mailchimp_key_iv"
    t.string "stylesheet_url"
    t.boolean "staff_access_only", default: false
    t.boolean "allow_guest_checkout", default: false
    t.string "feature_flags", default: "--- []\n"
    t.text "accessibility_advisory_for_reserved_seating", default: "This seat is designated as an accessible seat.  Please ensure you need this accommodation before finalizing this reservation.", null: false
    t.string "restrict_customer_email_to_domain"
    t.integer "order_timeout", default: 5, null: false
    t.datetime "last_sweep", default: "2020-01-03 12:12:28", null: false
    t.text "html_email_template", default: "<!DOCTYPE html>\n<html>\n  <!-- \n       You can replace this with an HTML template to style your transactional emails.\n  -->\n  <head>\n    <!-- CSS styling must be inline using <style> tags, preferably inside <head> element -->\n  </head>\n  <body>\n    <!-- Links to publicly-serveable external images are OK. -->\n    <!-- Avoid scripts (inline or linked) -- you'll be seen as a malware purveyor. -->\n\n    <!-- Body MUST contain the following string exactly once: -->\n\n    =+MESSAGE+=\n\n    <!-- It will be replaced with the email body, in a <div> with class \"a1-email\" -->\n\n    <hr>\n    \n    <!-- \n         If your template doesn't contain contact info, include the following string\n         and it will be replaced by contact info inside a <div> with class \"a1-email-footer\"\n      -->\n      \n    =+FOOTER+=\n    \n  </body>\n</html>\n", null: false
    t.string "reminder_emails", default: "Never"
    t.text "general_reminder_email_notes"
    t.integer "import_timeout", default: 15, null: false
    t.string "transactional_bcc_email"
    t.string "accessibility_needs_prompt", default: "Please describe (wheelchair, no stairs, etc.)"
    t.boolean "allow_recurring_donations", default: false
    t.string "default_donation_type", default: "one"
    t.text "recurring_donation_contact_emails"
    t.boolean "notify_theater_about_new_recurring_donation", default: true
    t.boolean "notify_theater_about_failed_recurring_donation_charge", default: true
  end

  create_table "orders", id: :serial, force: :cascade do |t|
    t.string "authorization", limit: 255
    t.integer "customer_id"
    t.integer "purchasemethod"
    t.integer "processed_by_id"
    t.datetime "sold_on"
    t.integer "purchaser_id"
    t.text "valid_vouchers"
    t.text "donation_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "walkup", default: false
    t.boolean "ship_to_purchaser", default: true
    t.text "retail_items"
    t.string "external_key"
    t.integer "ticket_sales_import_id"
    t.string "type", default: "Order", null: false
    t.text "from_import"
    t.index ["authorization"], name: "index_orders_on_authorization"
    t.index ["authorization"], name: "public_orders_authorization0_idx"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["customer_id"], name: "public_orders_customer_id2_idx"
    t.index ["external_key"], name: "index_orders_on_external_key"
    t.index ["processed_by_id"], name: "index_orders_on_processed_by_id"
    t.index ["purchaser_id"], name: "index_orders_on_purchaser_id"
    t.index ["purchaser_id"], name: "public_orders_purchaser_id3_idx"
    t.index ["ticket_sales_import_id"], name: "index_orders_on_ticket_sales_import_id"
    t.index ["walkup"], name: "index_orders_on_walkup"
    t.index ["walkup"], name: "public_orders_walkup1_idx"
  end

  create_table "recurring_donations", id: :serial, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "account_code_id"
    t.integer "processed_by_id"
    t.string "stripe_price_oid"
    t.string "state"
    t.integer "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "seating_zones", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.integer "display_order", default: 0
  end

  create_table "seatmaps", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "csv"
    t.text "json", null: false
    t.text "seat_list"
    t.integer "rows", default: 0, null: false
    t.integer "columns", default: 0, null: false
    t.string "image_url"
    t.text "zones", default: "--- {}\n"
  end

  create_table "showdates", id: :serial, force: :cascade do |t|
    t.datetime "thedate"
    t.integer "max_advance_sales", default: 0, null: false
    t.integer "show_id", default: 0, null: false
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "seatmap_id"
    t.integer "house_capacity", default: 0, null: false
    t.boolean "live_stream", default: false, null: false
    t.boolean "stream_anytime", default: false, null: false
    t.text "access_instructions"
    t.text "long_description"
    t.string "house_seats", limit: 8192
    t.index ["seatmap_id"], name: "index_showdates_on_seatmap_id"
    t.index ["show_id"], name: "index_showdates_on_show_id"
    t.index ["show_id"], name: "public_showdates_show_id1_idx"
  end

  create_table "shows", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "patron_notes"
    t.string "landing_page_url", limit: 255
    t.date "listing_date", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "event_type", limit: 255, default: "Regular Show", null: false
    t.string "sold_out_dropdown_message", limit: 255
    t.string "sold_out_customer_info", limit: 255
    t.integer "season", default: 2020, null: false
    t.string "reminder_type", default: "Never", null: false
  end

  create_table "ticket_sales_imports", id: :serial, force: :cascade do |t|
    t.string "vendor"
    t.text "raw_data"
    t.integer "processed_by_id"
    t.datetime "updated_at", null: false
    t.integer "tickets_sold"
    t.integer "new_customers"
    t.integer "existing_customers"
    t.string "filename"
    t.boolean "completed", default: false
    t.datetime "created_at"
    t.index ["processed_by_id"], name: "index_ticket_sales_imports_on_processed_by_id"
  end

  create_table "txns", id: :serial, force: :cascade do |t|
    t.integer "customer_id", default: 1, null: false
    t.integer "entered_by_id", default: 1, null: false
    t.datetime "txn_date"
    t.integer "show_id"
    t.integer "showdate_id"
    t.integer "purchasemethod"
    t.integer "voucher_id", default: 0, null: false
    t.float "dollar_amount", default: 0.0, null: false
    t.string "comments", limit: 255
    t.integer "order_id"
    t.string "txn_type", limit: 255
    t.index ["customer_id"], name: "index_txns_on_customer_id"
    t.index ["customer_id"], name: "public_txns_customer_id0_idx"
    t.index ["entered_by_id"], name: "index_txns_on_entered_by_id"
    t.index ["order_id"], name: "index_txns_on_order_id"
    t.index ["show_id"], name: "index_txns_on_show_id"
    t.index ["showdate_id"], name: "index_txns_on_showdate_id"
    t.index ["voucher_id"], name: "index_txns_on_voucher_id"
  end

  create_table "valid_vouchers", id: :serial, force: :cascade do |t|
    t.integer "showdate_id"
    t.integer "vouchertype_id"
    t.string "promo_code", limit: 1023
    t.datetime "start_sales"
    t.datetime "end_sales"
    t.integer "max_sales_for_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_sales_per_txn", default: 1
    t.integer "max_sales_per_txn", default: 100000
    t.index ["showdate_id", "vouchertype_id"], name: "index_valid_vouchers_on_showdate_id_and_vouchertype_id"
    t.index ["showdate_id", "vouchertype_id"], name: "public_valid_vouchers_showdate_id1_idx"
    t.index ["showdate_id"], name: "index_valid_vouchers_on_showdate_id"
    t.index ["showdate_id"], name: "public_valid_vouchers_showdate_id3_idx"
    t.index ["start_sales"], name: "index_valid_vouchers_on_start_sales"
    t.index ["start_sales"], name: "public_valid_vouchers_start_sales0_idx"
    t.index ["vouchertype_id"], name: "index_valid_vouchers_on_vouchertype_id"
    t.index ["vouchertype_id"], name: "public_valid_vouchers_vouchertype_id2_idx"
  end

  create_table "vouchertypes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.float "price", default: 0.0
    t.datetime "created_at"
    t.text "comments"
    t.integer "offer_public", default: 0, null: false
    t.boolean "subscription"
    t.text "included_vouchers"
    t.boolean "walkup_sale_allowed", default: false, null: false
    t.boolean "fulfillment_needed", default: false, null: false
    t.string "category", limit: 10
    t.integer "season", default: 2011, null: false
    t.boolean "changeable", default: false, null: false
    t.integer "account_code_id", default: 1, null: false
    t.integer "display_order", default: 0, null: false
    t.integer "seating_zone_id"
    t.datetime "updated_at"
    t.index ["account_code_id"], name: "index_vouchertypes_on_account_code_id"
    t.index ["category", "season"], name: "index_vouchertypes_on_category_and_season"
    t.index ["category", "season"], name: "public_vouchertypes_category4_idx"
    t.index ["category"], name: "index_vouchertypes_on_category"
    t.index ["category"], name: "public_vouchertypes_category2_idx"
    t.index ["season"], name: "index_vouchertypes_on_season"
    t.index ["season"], name: "public_vouchertypes_season3_idx"
    t.index ["subscription"], name: "index_vouchertypes_on_subscription"
    t.index ["subscription"], name: "public_vouchertypes_subscription0_idx"
    t.index ["walkup_sale_allowed"], name: "index_vouchertypes_on_walkup_sale_allowed"
    t.index ["walkup_sale_allowed"], name: "public_vouchertypes_walkup_sale_allowed1_idx"
  end

end
