class CreateCustomReports < ActiveRecord::Migration
  def self.up
    create_table :custom_reports do |t|
      t.column :sql, :text
      t.column :name, :string
      t.column :description, :string
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
      t.column :last_run_on, :datetime
      t.column :terms, :text
      t.column :conds, :text
      t.column :order, :string
    end
  end

  def self.down
    drop_table :custom_reports
  end
end
