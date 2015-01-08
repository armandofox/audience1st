class QuickDonationOptions < ActiveRecord::Migration
  def self.up
    add_column :options, :quick_donation_banner, :string, :default => 'Support us with a donation'
    add_column :options, :quick_donation_redirect, :string, :null => true, :default => nil
    add_column :options, :quick_donation_explanation, :text
    Option.reset_column_information
    Option.first.update_attribute(:quick_donation_explanation, 'Please fill out the information below to donate immediately online.')
  end

  def self.down
    remove_column :options, :quick_donation_banner
    remove_column :options, :quick_donation_explanation
  end
end
