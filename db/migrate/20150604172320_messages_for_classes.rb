class MessagesForClasses < ActiveRecord::Migration
  def self.up
    %w(current_subscribers nonsubscribers next_season_subscribers).each do |w|
      rename_column :options, "single_ticket_sales_banner_for_#{w}", "regular_show_sales_banner_for_#{w}"
      add_column :options, "class_sales_banner_for_#{w}", :string, :null => true, :default => nil
    end
    
  end

  def self.down
  end
end
