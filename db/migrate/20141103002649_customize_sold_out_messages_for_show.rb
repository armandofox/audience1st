class CustomizeSoldOutMessagesForShow < ActiveRecord::Migration
  def self.up
    add_column :shows, :sold_out_dropdown_message, :string, :null => true, :default => nil
    add_column :shows, :sold_out_customer_info, :string, :null => true, :default => nil
    Show.reset_column_information
    Show.update_all 'sold_out_dropdown_message="(Sold Out)"'
    Show.update_all 'sold_out_customer_info="No tickets on sale for this performance"'
  end

  def self.down
    remove_column :shows, :sold_out_dropdown_message
    remove_column :shows, :sold_out_customer_info
  end
end
