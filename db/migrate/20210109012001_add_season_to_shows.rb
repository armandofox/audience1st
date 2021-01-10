class AddSeasonToShows < ActiveRecord::Migration
  def change
    add_column :shows, :season, :integer, :null => false, :default => 2020
    Show.reset_column_information
    Show.transaction do
      Show.all.each do |show|
        season = (show.attributes['opening_date'] || show.listing_date).at_beginning_of_season.year
        show.update_attributes!(:season => season)
      end
    end
  end
end
