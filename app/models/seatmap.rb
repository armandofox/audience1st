class Seatmap < ActiveRecord::Base

  require 'csv'
  
  validates_uniqueness_of :name

  def parse_csv_to_json
    @as_js = []
    self.csv.each_line do |line|
      line.chomp!
      row_string = ''
      line.split(/\s*,\s*/).map { |s| s.gsub('"','') }.each do |cell|
        break if cell.strip == '.'
        if cell =~ /^\s*$/
          row_string << '_'
        else
          row_string << "r[#{cell}, ]"
        end
      end
      @as_js << "'#{row_string}'"
    end
    self.json = "{\n  map: [\n" << @as_js.join(",\n") << "\n  ]\n};\n"
  end
end
