class Seatmap < ActiveRecord::Base

  require 'csv'
  
  validates :name, :presence => true, :uniqueness => true
  validates :csv, :presence => true
  validates :json,  :presence => true
  validates :seat_list, :presence => true

  def self.seatmap_and_unavailable_seats_as_json(showdate)
    seatmap = showdate.seatmap.json
    unavailable = showdate.occupied_seats.to_json
    %Q{ {"map": #{seatmap}, "unavailable": #{unavailable}} }
  end

  # seatmap editor/parser stuff
  def includes_seat?(seat)
    seat_list.match Regexp.new("\\b#{seat}\\b")
  end

  def parse_csv
    @as_js = []
    list = []
    self.csv.each_line do |line|
      line.chomp!
      row_string = ''
      line.split(/\s*,\s*/).map { |s| s.gsub('"','') }.each do |cell|
        cell.strip!
        break if cell == '.'
        if cell =~ /^\s*$/
          row_string << '_'
        else
          row_string << "r[#{cell}, ]"
          list << cell
        end
      end
      @as_js << %Q{"#{row_string}"}
    end
    self.json = "[\n" << @as_js.join(",\n") << "\n  ]"
    self.seat_list = list.sort.join(',')
  end
end

