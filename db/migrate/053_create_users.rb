class CreateUsers < ActiveRecord::Migration
  def self.up
    add_column :customers, :name, :string, :limit => 100, :default => '', :null => true
    rename_column :customers, :hashed_password, :crypted_password
    change_column :customers, :salt, :string, :limit => 40
    rename_column :customers, :created_on, :created_at
    rename_column :customers, :updated_on, :updated_at
    add_column :customers, :remember_token,            :string, :limit => 40
    add_column :customers, :remember_token_expires_at, :datetime
    add_index :customers, :login, :unique => true
    # for Facebook Connect
    add_column :customers, :fb_user_id, :integer
    add_column :customers, :email_hash, :string
    # for mysql only
    execute("alter table customers modify fb_user_id bigint")
  end

  def self.down
    remove_column :customers, :name
    rename_column :customers, :crypted_password, :hashed_password
    rename_column :customers, :created_at, :created_on
    rename_column :customers, :updated_at, :updated_on
    remove_column :customers, :remember_token
    remove_column :customers, :remember_token_expires_at
    remove_column :customers, :fb_user_id
    remove_column :customers, :email_hash
  end
end
