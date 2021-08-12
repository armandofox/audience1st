class Seatmap < ActiveRecord::Base
  class Parser

    VALID_SEAT_LABEL_REGEX = /\A\s*([A-Za-z0-9]+):([A-Za-z0-9]+)(\+)?\s*\Z/
    ERR = 'seatmaps.errors.'      # base of i18n error message keys

    attr_accessor :seatmap

    def initialize(seatmap)
      @seatmap = seatmap
      @all_zones = SeatingZone.hash_by_short_name # zones['r'] => 'Reserved'
      @seat_rows = []
      @dups = {}
      @missing_zones = {}
      @invalid_seats = []
      @list = []
    end
    
    def parse_csv
      seatmap.zones = {}
      seatmap.json = seatmap.seat_list = ''
      seatmap.rows = seatmap.columns = 0
      @seat_rows = CSV.parse(seatmap.csv)
      pad_rows_to_uniform_length!
      parse_rows
    end

    private

    def parse_rows
      @as_js = []
      @seat_rows.each do |row|
        row_string = ''
        row.each do |cell|
          if cell.blank?   # no seat in this location
            row_string << '_'
          else
            next unless parse_valid_seat_label(cell)
            next unless zone_exists
            next unless seat_number_is_unique
            # icons don't work with jQuery seatmaps yet...
            # label = (seat_type == 'r' ? ' ' : '\u267F')     # unicode HTML glyph for wheelchair
            # and the 'A' labels for accessible seats don't align right...
            # label = (seat_type == 'r' ? ' ' : 'A')
            # so just fall back for now
            label = ' '
            row_string << "#{@seat_type}[#{@zone_name}-#{@seat_number},#{label}]"
            @list << @seat_number
            (seatmap.zones[@zone_short_name] ||= []) << @seat_number
          end
        end
        @as_js << %Q{"#{row_string}"}
      end
      collect_errors
      seatmap.json = "[\n" << @as_js.join(",\n") << "\n  ]"
      seatmap.seat_list = @list.sort.join(',')
      seatmap.columns = @seat_rows.map(&:length).max
      seatmap.rows = @seat_rows.length
    end

    def pad_rows_to_uniform_length!
      len = @seat_rows.map(&:length).max
      @seat_rows.each { |r| (r << Array.new(len - r.length) {''}).flatten! }
    end

    def parse_valid_seat_label(cell)
      if cell =~ VALID_SEAT_LABEL_REGEX
        @seat_type = ($3 == '+' ? 'a' : 'r') # accessible or regular seat
        @zone_short_name,@seat_number = $1, $2
      else
        @invalid_seats << cell
        false
      end
    end

    def seat_number_is_unique
      if @list.include?(@seat_number)
        @dups[@seat_number] = true
        false
      else
        true
      end
    end

    def zone_exists
      if (@zone_name = @all_zones[@zone_short_name]).blank?
        @missing_zones[@zone_short_name] = true
        false
      else
        true
      end
    end

    def collect_errors
      seatmap.errors.add(:base, I18n.translate("#{ERR}invalid_seat_label", :cells => @invalid_seats.join(', '))) unless
        @invalid_seats.empty?
      seatmap.errors.add(:base, I18n.translate("#{ERR}no_such_zone", :zones => @missing_zones.keys.join(', '))) unless
        @missing_zones.empty?
      seatmap.errors.add(:base, I18n.translate("#{ERR}dups", :seats => @dups.keys.join(', '))) unless
        @dups.empty?
    end

  end
end
