class CreateTicketSalesImports < ActiveRecord::Migration
  def change
    create_table :ticket_sales_imports, :force => true do |t|
      t.string :vendor
      t.text :raw_data
      t.references :processed_by
      t.timestamps null: false
    end
    change_table :orders do |t|
      t.string :external_key
      t.index :external_key, :unique => true
    end
  end
end
