class Seatmap < ActiveRecord::Base

  require 'csv'
  
  validates_presence_of :name
  validates_uniqueness_of :name

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
      @as_js << "'#{row_string}'"
    end
    self.json = "[\n" << @as_js.join(",\n") << "\n  ]"
    self.seat_list = list.sort.join(',')
  end
end
