class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts, :force => true do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column "Customer".foreign_key, :integer
      t.column :referred_by_id, :integer, :null => true, :default => nil
      t.column :referred_by_other, :string
      t.column (:formal_relationship, :enum,
                :limit => ['None', 'Board Member', 'Former Board Member',
                           'Board President', 'Former Board President',
                           'Honorary Board Member', 'Emeritus Board Member'])
      t.column (:member_type, :enum,
                :limit => ['None', 'Regular', 'Sustaining', 'Life',
                           'Honorary Life'])
      t.column :company, :string
      t.column :title, :string
      t.column :address_line_1, :string
      t.column :address_line_2, :string
      t.column :city, :string
      t.column :state, :string
      t.column :zip, :string
      t.column :work_phone, :string
      t.column :cell_phone, :string
      t.column :work_fax, :string
      t.column :url, :string
    end
    create_table :visits, :force => true do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      # visited_by will default to logged-in ID
      t.column :visited_by_id, :integer, :null => false, :default => 0
      t.column (:contact_method, :enum,
                :limit => ['Phone', 'Email', 'Letter/Fax', 'In person'])
      t.column :location, :string
      t.column (:purpose, :enum,
                :limit => ['Preliminary', 'Followup', 'Presentation',
                           'Further Discussion', 'Close', 'Recognition',
                           'Other'])
      t.column (:result, :enum,
                :limit => ['No interest', 'Further cultivation',
                           'Arrange for Gift', 'Gift Received'])
      t.column :additional_notes, :string
      t.column :followup_date, :date
      t.column :followup_action, :string
      t.column :next_ask_target, :integer, :default => 0, :null => false
      # followup_assigned_to will default to logge-in ID
      t.column :followup_assigned_to_id, :integer, :null => false, :default => 0
    end
    create_table :contacts_visits, :id => false do |t|
      t.column :contact_id, :integer
      t.column :visit_id, :integer
    end
    add_index :contacts_visits, :contact_id
  end

  def self.down
    drop_table :contacts
    drop_table :visits
    drop_table :contacts_visits
  end
end
