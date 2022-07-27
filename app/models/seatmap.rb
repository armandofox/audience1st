class Seatmap < ActiveRecord::Base

  has_many :showdates
  
  require 'uri'
  
  serialize :zones, Hash

  class AsJson
    attr_reader :seatmap
    attr_accessor :seats, :selected, :unavailable, :holdback
    def initialize(seatmap)
      # initialize to empty
      @seatmap = seatmap
      @seats = {}
      @selected = []
      @unavailable = []
      @holdback = []
    end
    def self.empty
      {'map' => [], 'seats' => {}, 'unavailable' => [], 'rows' => 0, 'columns' => 0}.to_json
    end

    # Return JSON object with fields 'map' (JSON representation of actual seatmap),
    # 'seats' (types of seats to display), 'image_url' (background image)
    def emit_json
      _seatmap = seatmap.json
      image_url = seatmap.image_url.to_json
      # if seatmap has only one zone, hide zone name during seat selection
      hide_zone_name = (!!(seatmap.zones.keys.length == 1)).to_json
      # since the 'unavailable' and 'selected' values are used by the actual
      # seatmap JS code to identify seats, labels must include the full seating zone display name.
      _unavailable = @unavailable.compact.map { |num| seatmap.hover_label_with_zone(num) }.to_json
      _selected = @selected.compact.map { |num| seatmap.hover_label_with_zone(num) }.to_json
      _holdback = @holdback.compact.map { |num| seatmap.hover_label_with_zone(num) }.to_json
      # seat classes: 'r' = regular, 'a' = accessible
      seats = {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}.to_json
      %Q{ {"map": #{_seatmap},
"rows": #{seatmap.rows},
"columns": #{seatmap.columns},
"seats": #{seats},
"unavailable": #{_unavailable},
"selected": #{_selected},
"holdback": #{_holdback},
"hideZoneName": #{hide_zone_name},
"image_url": #{image_url} }}
    end
  end

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
  # 'seats' (types of seats to display), 'image_url' (background image),
  # 'unavailable' (list of unavailable seats for a given showdate)
  def self.seatmap_and_unavailable_seats_as_json(showdate, restrict_to_zone: nil, selected: [], is_boxoffice: false)
    return Seatmap::AsJson.empty unless (sm = showdate.seatmap)
    map = Seatmap::AsJson.new(sm)
    map.selected = selected
    map.holdback = showdate.holdback_seats.sort
    # if any preselected seats, show them as selected not occupied
    occupied = showdate.occupied_seats - selected
    occupied += sm.excluded_from_zone(restrict_to_zone) unless restrict_to_zone.blank?
    # remove any seats that are held back by boxoffice
    occupied += map.holdback unless is_boxoffice
    map.unavailable = occupied.sort.uniq
    map.emit_json
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

  # Enumerate the associated zones, as SeatingZone instances
  def seating_zones
    self.zones.keys.map { |short_name| SeatingZone.find_by!(:short_name => short_name) }
  end
  
  # Enumerate the seat numbers in a particular zone
  def seats_in_zone(zone)
    self.zones[zone.short_name]
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

  # hover label including zone
  def hover_label_with_zone(seat)
    "#{self.zone_displayed_for(seat)}-#{seat}"
  end
  
  # Does this seatmap reference a particular zone or not ?
  def references_zone?(zone)
    csv =~ /\b#{zone.short_name}:/
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
