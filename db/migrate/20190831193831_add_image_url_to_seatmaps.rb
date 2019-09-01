class AddImageUrlToSeatmaps < ActiveRecord::Migration
  def change
    change_table 'seatmaps' do |t|
      t.string :image_url
    end
  end
end
