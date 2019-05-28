class AddTicketSalesImportIdToOrders < ActiveRecord::Migration
  def change
    change_table :orders do |t|
      t.references 'ticket_sales_import'
    end
  end
end
