class ConvertSeatmapsToUseZones < ActiveRecord::Migration
  # add the default seating zone 'reg' to all seats in all seatmaps.
  # to do this, grab the CSV, modify it, save it, and re-parse it.
  def change
    Seatmap.all.each do |s|
      s.csv.gsub!( /([A-Za-z0-9]+)/, 'reg:\1' )
      s.parse_csv
      s.zones = {'reg' => s.seat_list}
      raise "Aborting: #{s.errors.full_messages}" unless s.valid?
      s.save!
    end
  end
end
