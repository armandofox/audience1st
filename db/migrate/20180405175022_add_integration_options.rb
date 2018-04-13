class AddIntegrationOptions < ActiveRecord::Migration
  def change
    change_table :options do |t|
      t.string           :stripe_key
      t.string :encrypted_stripe_secret      ; t.string :encrypted_stripe_secret_iv
      t.string           :sendgrid_key_name
      t.string :encrypted_sendgrid_key_value ; t.string :encrypted_sendgrid_key_value_iv
      t.string           :sendgrid_domain
      t.string :encrypted_mailchimp_key      ; t.string :encrypted_mailchimp_key_iv
      t.string           :stylesheet_url
      t.boolean          :staff_access_only, :default => false
      t.string :encrypted_maintenance_password; t.string :encrypted_maintenance_password_iv
    end
  end
end
