class AddColumnsToTicketSalesImport < ActiveRecord::Migration
  def change
    change_table :ticket_sales_imports do |t|
      t.integer :tickets_sold
      t.integer :new_customers
      t.integer :existing_customers
    end
  end
end
