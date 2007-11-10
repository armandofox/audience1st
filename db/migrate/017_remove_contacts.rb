class RemoveContacts < ActiveRecord::Migration
  def self.up
    add_column :customers, :is_contact, :boolean, :default => false
    add_column :customers, :referred_by_id, :integer, :null => true, :default => nil
    add_column :customers, :referred_by_other, :string
    add_column :customers, :formal_relationship, :enum,
    :limit => ['None', 'Board Member', 'Former Board Member',
               'Board President', 'Former Board President',
               'Honorary Board Member', 'Emeritus Board Member'],
    :default => 'None'
    add_column :customers, :member_type, :enum,
    :limit => ['None', 'Regular', 'Sustaining', 'Life', 'Honorary Life'],
    :default => 'None'
    add_column :customers, :company, :string, :null => true, :default => nil
    add_column :customers, :title, :string, :null => true, :default => nil
    add_column :customers, :company_address_line_1, :string, :null => true, :default => nil
    add_column :customers, :company_address_line_2, :string, :null => true, :default => nil
    add_column :customers, :company_city, :string, :null => true, :default => nil
    add_column :customers, :company_state, :string, :null => true, :default => nil
    add_column :customers, :company_zip, :string, :null => true, :default => nil
    add_column :customers, :work_phone, :string, :null => true, :default => nil
    add_column :customers, :cell_phone, :string, :null => true, :default => nil
    add_column :customers, :work_fax, :string, :null => true, :default => nil
    add_column :customers, :company_url, :string, :null => true, :default => nil

    remove_column :visits, "Contact".foreign_key
    add_column :visits, "Customer".foreign_key, :integer
    
    drop_table :contacts
  end

  def self.down
  end
end
