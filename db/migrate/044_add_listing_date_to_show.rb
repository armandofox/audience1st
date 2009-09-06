class AddListingDateToShow < ActiveRecord::Migration
  def self.up
    add_column :shows, :listing_date, :date, :null => false, :default => Date.today
    Show.reset_column_information
    Show.find(:all).each do |show|
      show.update_attribute(:listing_date, (show.opening_date - 3.months).to_date)
    end
  end

  def self.down
    remove_column :shows, :listing_date
  end
end
