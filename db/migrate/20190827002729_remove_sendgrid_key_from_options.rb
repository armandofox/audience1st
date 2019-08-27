class RemoveSendgridKeyFromOptions < ActiveRecord::Migration
  def change
    remove_column :options, :encrypted_sendgrid_key_value
    remove_column :options, :encrypted_sendgrid_key_value_iv
  end
end
