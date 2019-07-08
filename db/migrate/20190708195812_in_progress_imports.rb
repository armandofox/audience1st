class InProgressImports < ActiveRecord::Migration
  def change
    remove_column :ticket_sales_imports, :created_at
    add_column :ticket_sales_imports, :completed, :boolean, :default => false
  end
end
