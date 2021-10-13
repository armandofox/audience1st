class Seatmap < ActiveRecord::Base

  has_many :showdates
  
  require 'uri'
  
  serialize :zones, Hash

  EMPTY_SEATMAP_AS_JSON =
    {'map' => [], 'seats' => {}, 'unavailable' => [], 'rows' => 0, 'columns' => 0}.to_json

  validates :name, :presence => true, :uniqueness => true
  validates :csv, :presence => true
  validates_format_of :image_url, :with => URI.regexp, :allow_blank => true
  validate :valid_csv, :if => :new_record?

  private

  def valid_csv
    Seatmap::Parser.new(self).parse_csv
  end

  public
  
  # Return JSON object with fields 'map' (JSON representation of actual seatmap),
  # 'seats' (types of seats to display), 'image_url' (background image)

  def emit_json(unavailable = [])
    seatmap = self.json
    image_url = self.image_url.to_json
    # since the 'unavailable' value is used by the actual seatmap JS code to identify seats,
    #  the unavailable seats must include the full seating zone display name.
    unavailable = unavailable.compact.map { |num| "#{zone_displayed_for(num)}-#{num}" }.to_json
    # seat classes: 'r' = regular, 'a' = accessible
    seats = {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}.to_json
    %Q{ {"map": #{seatmap}, "rows": #{rows}, "columns": #{columns}, "seats": #{seats}, "unavailable": #{unavailable}, "image_url": #{image_url} }}
  end

  # Return JSON object with fields 'map' (JSON representation of actual seatmap),
  # 'seats' (types of seats to display), 'image_url' (background image),
  # 'unavailable' (list of unavailable seats for a given showdate)
  def self.seatmap_and_unavailable_seats_as_json(showdate, restrict_to_zone)
    return EMPTY_SEATMAP_AS_JSON unless (sm = showdate.seatmap)
    occupied = showdate.occupied_seats
    if !restrict_to_zone.blank?
      occupied = (occupied + sm.excluded_from_zone(restrict_to_zone)).sort.uniq
    end
    sm.emit_json(occupied)
  end

  # Return JSON hash of ids to seat counts
  def self.capacities_as_json
    Hash[Seatmap.all.map { |s| [s.id.to_s, s.seat_count.to_s] }].to_json
  end

  # How many seats?  (includes accessible)
  def seat_count
    @seat_count ||= seat_list.split(/\s*,\s*/).size
  end

  def name_with_capacity
    "#{name} (#{seat_count})"
  end

  # Seats excluded from a zone (ie, any seats NOT in that zone
  def excluded_from_zone(restrict_to_zone)
    excluded = []
    self.zones.each_pair do |shortname, seats|
      excluded += seats unless shortname == restrict_to_zone
    end
    excluded.sort
  end

  # To which zone does a seat belong?
  def zone_displayed_for(seat)
    key = self.zones.keys.detect { |k| zones[k].include?(seat) }
    SeatingZone.find_by!(:short_name => key).name
  end

  # Given a collection of vouchers, some of which may have seat numbers, return the subset
  # that COULD NOT be accommodated by this seatmap.  Used to determine if it's possible to
  # change a seatmap for a performance after sales have begun.
  def cannot_accommodate(vouchers)
    seats = self.seat_list.split(/\s*,\s*/)
    vouchers.select do |v|
      ! v.seat.blank?  &&  ! seats.include?(v.seat)
    end
  end

  # seatmap editor/parser stuff
  def includes_seat?(seat)
    seat_list.match Regexp.new("\\b#{seat}\\b")
  end

  def update!
    Seatmap::Parser.new(self).parse_csv
    save!
  end

end
