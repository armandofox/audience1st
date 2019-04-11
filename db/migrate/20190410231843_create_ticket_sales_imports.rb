class CreateTicketSalesImports < ActiveRecord::Migration
  def change
    create_table :ticket_sales_imports, :force => true do |t|

      t.string :vendor
      t.text :raw_data
      t.boolean :completed

      t.timestamps null: false
    end
  end
end
