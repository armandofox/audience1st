class AddImageUrlToSeatmaps < ActiveRecord::Migration
  def change
    change_table 'seatmaps' do |t|
      t.string :background_image_url
    end
  end
end
