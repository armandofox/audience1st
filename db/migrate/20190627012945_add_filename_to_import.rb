class AddFilenameToImport < ActiveRecord::Migration
  def change
    change_table :ticket_sales_imports do |t|
      t.string :filename
    end
  end
end
