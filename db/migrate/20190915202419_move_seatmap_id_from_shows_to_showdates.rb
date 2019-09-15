class MoveSeatmapIdFromShowsToShowdates < ActiveRecord::Migration
  def change
    change_table :showdates do |t|
      t.references 'seatmap'
    end
    Showdate.connection.schema_cache.clear!
    Showdate.reset_column_information
    Show.where('seatmap_id IS NOT NULL').each do |show|
      show.showdates.update_all(:seatmap_id => 1)
    end
    remove_column :shows, :seatmap_id
  end
end
