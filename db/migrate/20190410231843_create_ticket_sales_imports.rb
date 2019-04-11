class CreateTicketSalesImports < ActiveRecord::Migration
  def change
    create_table :ticket_sales_imports do |t|

      t.timestamps null: false
    end
  end
end
