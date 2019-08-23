class AddSeatListToSeatmap < ActiveRecord::Migration
  def change
    change_table :seatmaps do |t|
      t.text :seat_list
    end
    # update the seatmaps in place to regenerate this
    Seatmap.all.each do |s|
      s.parse_csv
      s.save!
    end
  end
end
