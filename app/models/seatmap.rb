class Seatmap < ActiveRecord::Base

  has_many :showdates
  
  require 'csv'
  require 'uri'
  
  serialize :zones, Hash

  VALID_SEAT_LABEL_REGEX = /\A\s*([A-Za-z0-9]+):([A-Za-z0-9]+)(\+)?\s*\Z/
  ERR = 'seatmaps.errors.'      # base of i18n error message keys

  EMPTY_SEATMAP_AS_JSON =
    {'map' => [], 'seats' => {}, 'unavailable' => [], 'rows' => 0, 'columns' => 0}.to_json
  
  validates :name, :presence => true, :uniqueness => true
  validates :csv, :presence => true
  validates :json,  :presence => true
  validates :seat_list, :presence => true
  validates_numericality_of :rows, :greater_than => 0
  validates_numericality_of :columns, :greater_than => 0
  validate :no_duplicate_seats
  validate :all_zones_exist
  
  validates_format_of :image_url, :with => URI.regexp, :allow_blank => true

  attr_accessor :seat_rows
  
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
    parse_csv
    save!
  end

  def parse_csv
    @seat_rows = CSV.parse(self.csv)
    pad_rows_to_uniform_length!
    parse_rows
  end

  def parse_rows
    all_zones = SeatingZone.hash_by_short_name # zones['r'] => 'Reserved'
    list = []
    @as_js = []
    @seat_rows.each do |row|
      row_string = ''
      row.each do |cell|
        if cell.blank?   # no seat in this location
          row_string << '_'
        else
          unless cell =~ VALID_SEAT_LABEL_REGEX
            return errors.add(:base, I18n.translate("#{ERR}invalid_seat_label", :cell => cell))
          end
          seat_type = ($3 == '+' ? 'a' : 'r') # accessible or regular seat
          zone_short_name,seat_number = $1, $2
          if (zone_name = all_zones[zone_short_name]).blank?
            return errors.add(:base, I18n.translate("#{ERR}no_such_zone", :zone => zone_short_name))
          end
          # icons don't work with jQuery seatmaps yet...
          # label = (seat_type == 'r' ? ' ' : '\u267F')     # unicode HTML glyph for wheelchair
          # and the 'A' labels for accessible seats don't align right...
          # label = (seat_type == 'r' ? ' ' : 'A')
          # so just fall back for now
          label = ' '
          row_string << "#{seat_type}[#{zone_name}-#{seat_number},#{label}]"
          list << seat_number
          (zones[zone_short_name] ||= []) << seat_number
        end
      end
      @as_js << %Q{"#{row_string}"}
    end
    self.json = "[\n" << @as_js.join(",\n") << "\n  ]"
    self.seat_list = list.sort.join(',')
    self.columns = @seat_rows.map(&:length).max
    self.rows = @seat_rows.length
  end

  private

  def pad_rows_to_uniform_length!
    len = @seat_rows.map(&:length).max
    @seat_rows.each { |r| (r << Array.new(len - r.length) {''}).flatten! }
  end

  def all_zones_exist
    all_zones = SeatingZone.hash_by_short_name
    missing = self.zones.keys - all_zones.keys
    unless missing.empty?
      missing.each do |z|
        @errors.add(:base, I18n.translate("#{ERR}no_such_zone", :zone => z))
      end
    end
  end

  def no_duplicate_seats
    parse_csv if seat_list.nil? || seat_list.empty?
    canonical = seat_list.to_s.split(/\s*,\s*/).map { |s| s.gsub(/\+$/, '') }
    dups = canonical.select.with_index do |e, i|
      i
      canonical.index(e)
      i != canonical.index(e)
    end
    unless dups.empty?
      @errors.add(:base, I18n.translate("#{ERR}dups", :seats => dups.join(', ')))
    end
  end
end

