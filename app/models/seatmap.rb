class Seatmap < ActiveRecord::Base

  has_many :showdates
  
  require 'csv'
  require 'uri'
  
  VALID_SEAT_LABEL_REGEX = /^\s*[A-Za-z0-9]+\+?\s*$/

  validates :name, :presence => true, :uniqueness => true
  validates :csv, :presence => true
  validates :json,  :presence => true
  validates :seat_list, :presence => true
  validates_numericality_of :rows, :greater_than => 0
  validates_numericality_of :columns, :greater_than => 0
  validate :no_duplicate_seats
  
  validates_format_of :image_url, :with => URI.regexp, :allow_blank => true
  # remove when we move to strong params
  attr_accessible :image_url, :name

  # Return JSON object with fields 'map' (JSON representation of actual seatmap),
  # 'seats' (types of seats to display), 'image_url' (background image)

  def emit_json(unavailable = [])
    seatmap = self.json
    image_url = self.image_url.to_json
    unavailable = unavailable.compact.to_json
    # seat classes: 'r' = regular, 'a' = accessible
    seats = {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}.to_json
    %Q{ {"map": #{seatmap}, "rows": #{rows}, "columns": #{columns}, "seats": #{seats}, "unavailable": #{unavailable}, "image_url": #{image_url} }}
  end

  # Return JSON object with fields 'map' (JSON representation of actual seatmap),
  # 'seats' (types of seats to display), 'image_url' (background image),
  # 'unavailable' (list of unavailable seats for a given showdate)
  def self.seatmap_and_unavailable_seats_as_json(showdate)
    showdate.seatmap.emit_json(showdate.occupied_seats)
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
    @as_js = []
    list = []
    @rows = CSV.parse(self.csv)
    pad_rows_to_uniform_length!
    @rows.each do |row|
      row_string = ''
      row.each do |cell|
        if cell.blank?   # no seat in this location
          row_string << '_'
        else
          cell = cell.strip.upcase
          return errors.add(:base, "Invalid seat label #{cell} (may contain only letters, numbers, and trailing + sign for accessible seats") unless cell =~ VALID_SEAT_LABEL_REGEX
          seat_type = (cell.sub!( /\+$/, '') ? 'a' : 'r') # accessible or regular seat
          # icons don't work with jQuery seatmaps yet...
          # label = (seat_type == 'r' ? ' ' : '\u267F')     # unicode HTML glyph for wheelchair
          # and the 'A' labels for accessible seats don't align right...
          # label = (seat_type == 'r' ? ' ' : 'A')
          # so just fall back for now
          label = ' '
          row_string << "#{seat_type}[#{cell},#{label}]"
          list << cell
        end
      end
      @as_js << %Q{"#{row_string}"}
    end
    self.json = "[\n" << @as_js.join(",\n") << "\n  ]"
    self.seat_list = list.sort.join(',')
  end

  private

  def pad_rows_to_uniform_length!
    len = @rows.map(&:length).max
    @rows.each { |r| (r << Array.new(len - r.length) {''}).flatten! }
    self.columns = len
    self.rows = @rows.length
  end

  def no_duplicate_seats
    parse_csv if seat_list.empty?
    canonical = seat_list.split(/\s*,\s*/).map { |s| s.gsub(/\+$/, '') }
    dups = canonical.select.with_index do |e, i|
      i
      canonical.index(e)
      i != canonical.index(e)
    end
    unless dups.empty?
      @errors.add(:base, "Seatmap contains duplicate seats: #{dups.join(', ')}")
    end
  end
end

