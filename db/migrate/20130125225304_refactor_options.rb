class RefactorOptions < ActiveRecord::Migration
  class OldOption < ActiveRecord::Base ; end
  def self.option(typ, name, opts={})
    add_column :options, name, typ, opts
    val = OldOption.find_by_name(name).value rescue nil
    val = if typ == :integer then val.to_i
          elsif typ == :boolean then !val.to_i.zero?
          else val.to_s
          end
    Option.reset_column_information
    Option.first.update_attribute(name, val)
  end
  def self.up
    rename_table :options, :old_options
    create_table :options, :force => true  do |t|
      t.timestamps
    end
    Option.reset_column_information
    OldOption.reset_column_information
    connection.execute("INSERT INTO options (created_at,updated_at) VALUES (NOW(), NOW())") # the singleton
    option :integer, :venue_id
    option :string,  :venue_shortname
    option :boolean, :sandbox, :default => false
    
    option :integer, :advance_sales_cutoff,       :default => 5
    option :integer, :sold_out_threshold,         :default => 90
    option :integer, :nearly_sold_out_threshold,  :default => 80
    option :boolean, :allow_gift_tickets,         :default => false
    option :boolean, :allow_gift_subscriptions,   :default => false
    option :integer, :season_start_month,         :default => 1
    option :integer, :season_start_day,           :default => 1
    option :integer, :cancel_grace_period,        :default => 1440
    option :string, :default_donation_account_code, :null => true, :default => nil
    option :string, :default_donation_account_code_with_subscriptions, :null => true, :default => nil

    option :string, :venue, :null => false,         :default => 'Enter Venue Name'
    option :string, :venue_address, :null => false, :default => 'Enter Venue Address'
    option :string, :venue_city_state_zip, :null => false, :default => 'Enter Venue City State Zip'
    option :string, :venue_telephone,      :null => false, :default => 'Enter Venue Main Phone'
    option :string, :venue_homepage_url,   :null => true, :default => nil
    option :string, :boxoffice_telephone,  :null => false, :default => 'Enter Venue Box office phone'
    option :string, :donation_ack_from,    :null => true, :default => nil

    option :string, :boxoffice_daemon_notify, :null => true, :default => nil
    option :string, :help_email,              :null => false, :default => 'Enter Help Email'
    option :integer, :followup_visit_reminder_lead_time, :null => false, :default => 0
    option :integer, :send_birthday_reminders, :null => false, :default => 0

    option :integer, :session_timeout, :null => false, :default => 1000

    %w(welcome_page_subscriber_message   welcome_page_nonsubscriber_message).
      each do |w|
      option :text, w, :null => true, :default => nil
    end
    %w(special_event subscription single_ticket).each do |s|
      %w(current_ next_season_ non).each do |t|
        option :text, "#{s}_sales_banner_for_#{t}subscribers", :null => true, :default => nil
      end
    end
    option :text, :top_level_banner_text, :null => true, :default => nil
    option :string, :homepage_ticket_sales_text, :null => true, :default => nil
    option :string, :homepage_subscription_sales_text, :null => true, :default => nil

    option :boolean, :display_email_opt_out, :default => true
    option :string, :encourage_email_opt_in, :null => true, :default => nil

    option :text, :checkout_notices, :null => true, :default => nil
    option :text, :precheckout_popup, :null => true, :default => nil
    option :text, :accessible_seating_notices, :null => true, :default => nil

    %w(subscription_purchase general_confirmation subscriber_confirmation nonsubscriber_confirmation).each do |n|
      option :text, "#{n}_email_notes", :null => true, :default => nil
    end
    option :text, :terms_of_sale, :null => true, :default => nil
    option :string, :stripe_publishable_key, :null => true, :default => nil
    option :string, :stripe_secret_key, :null => true, :default => nil
    option :string, :privacy_policy_url, :null => false, :default => 'Enter privacy policy page URL'
    option :string, :mailchimp_api_key, :null => true, :default => nil
    option :string, :mailchimp_default_list_name, :null => true, :default => nil
    add_column :options, :constant_contact_username, :string, :null => true, :default => nil
    add_column :options, :constant_contact_password, :string, :null => true, :default => nil
    add_column :options, :constant_contact_api_key, :string, :null => true, :default => nil
    drop_table :old_options
  end

  def self.down
  end
end
