class AddEmailIndexAndCreatedByAdmin < ActiveRecord::Migration
  def self.up
    add_column :customers, :created_by_admin, :boolean, :null => true, :default => nil
    add_column :customers, :tags, :string, :null => true, :default => nil
    add_column :customers, :inactive, :boolean, :null => true, :default => nil
    remove_column :customers, :phplist_user_id
    remove_column :customers, :formal_relationship
    remove_column :customers, :member_type
    remove_column :customers, :validation_level
    add_index :customers, :email
  end

  def self.down
    remove_column :customers, :created_by_admin
    remove_column :customers, :tags
    remove_column :customers, :inactive
    remove_index :customers, :email
  end
end
