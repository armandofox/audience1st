class AddTimestampsToTicketSalesImport < ActiveRecord::Migration
  def change
    change_table 'ticket_sales_imports' do |t|
      t.datetime :created_at
    end
  end
end
