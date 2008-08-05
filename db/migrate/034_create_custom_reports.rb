class CreateCustomReports < ActiveRecord::Migration
  def self.up
    create_table :custom_reports, :force => true do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :selected_clauses, :text
      t.column :selected_fields, :text
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
      t.column :last_run_at, :datetime
    end
  end

  def self.down
    drop_table :custom_reports
  end
end
