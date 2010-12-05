class AddCustomerLabels < ActiveRecord::Migration
  def self.up
    create_table 'labels', :force => true do |t|
      t.string :name
    end
    create_table 'customers_labels', :id => false, :force => true do |t|
      t.references :customer
      t.references :label
    end
  end

  def self.down
    drop_table 'customers_labels'
    drop_table 'labels'
  end
end
