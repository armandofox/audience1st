class Seatmap < ActiveRecord::Base

  require 'csv'
  
  validates :name, :presence => true, :uniqueness => true
  validates :csv, :presence => true
  validates :json,  :presence => true
  validates :seat_list, :presence => true
  validates_numericality_of :rows, :greater_than => 0
  validates_numericality_of :columns, :greater_than => 0

  def self.seatmap_and_unavailable_seats_as_json(showdate)
    seatmap = showdate.seatmap.json
    unavailable = showdate.occupied_seats.to_json
    # seat classes: 'r' = regular, 'a' = accessible
    seats = {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}.to_json
    %Q{ {"map": #{seatmap}, "seats": #{seats}, "unavailable": #{unavailable}} }
  end

  # seatmap editor/parser stuff
  def includes_seat?(seat)
    seat_list.match Regexp.new("\\b#{seat}\\b")
  end

  def parse_csv
    @as_js = []
    list = []
    @rows = CSV.parse(self.csv)
    pad_rows_to_uniform_length!
    @rows.each do |row|
      row_string = ''
      row.each do |cell|
        cell = cell.strip.upcase
        if cell.blank?   # no seat in this location
          row_string << '_'
        else
          seat_type = (cell.sub!( /\+$/, '') ? 'a' : 'r') # accessible or regular seat
          row_string << "#{seat_type}[#{cell}, ]"
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
end

