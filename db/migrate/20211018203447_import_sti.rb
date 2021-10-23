class ImportSti < ActiveRecord::Migration
  def change
    change_table 'orders', :force => true do |t|
      t.string 'type'
      t.text 'from_import'
    end
    Order.reset_column_information
    Order.update_all(:type => 'Order')
  end
end
