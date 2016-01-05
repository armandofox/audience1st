class RemoveApiKeysFromOptions < ActiveRecord::Migration
  def self.up
    remove_column :options, :stripe_publishable_key
    remove_column :options, :stripe_secret_key
    remove_column :options, :mailchimp_api_key
    remove_column :options, :sandbox
    remove_column :options, :constant_contact_username
    remove_column :options, :constant_contact_password
    remove_column :options, :constant_contact_api_key
  end

  def self.down
  end
end
