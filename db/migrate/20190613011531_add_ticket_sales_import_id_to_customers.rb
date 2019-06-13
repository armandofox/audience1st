class AddTicketSalesImportIdToCustomers < ActiveRecord::Migration
  def change
    change_table :customers do |t|
      t.belongs_to :ticket_sales_import
    end
  end
end
