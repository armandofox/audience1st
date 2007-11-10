class ContactsChanges < ActiveRecord::Migration
  def self.up
    drop_table :contacts_visits
    add_column :visits, "Contact".foreign_key, :integer
  end

  def self.down
    remove_column :visits, "Contact".foreign_key
  end
end
