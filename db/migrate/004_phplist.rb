class Phplist < ActiveRecord::Migration
  def self.up
    rename_column :customers, :phplist_user_user_id, :phplist_user_id
  end

  def self.down
    rename_column :customers, :phplist_user_id, :phplist_user_user_id
  end
end
