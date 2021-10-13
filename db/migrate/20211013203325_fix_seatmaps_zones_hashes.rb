class FixSeatmapsZonesHashes < ActiveRecord::Migration
  # somehow, some of the 'zones' hashes for seatmaps ended up looking like this
  #    "key1" => "A1,A2,A3"
  # instead of this
  #    "key1" => ["A1", "A2", "A3"]
  # which causes problems in the logic.  Not sure how happened, but fix them.
  def change
    Seatmap.all.each do |sm|
      modified = false
      zones = sm.zones
      zones.each_pair do |key,list|
        if list.kind_of?(String)
          modified = true
          zones[key] = list.split(/\s*,\s*/)
        end
      end
      sm.update_attributes!(:zones => zones) if modified
    end
  end
end
