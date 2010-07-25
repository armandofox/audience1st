#!/usr/bin/env ruby
# ParseExcel -- parseexcel -- 29.08.2006 -- hwyss@ywesee.com

require 'parseexcel/parseexcel'

# There is a problem with Spreadsheet::ParseExcel wherein some of the strings
# parsed from recent Excel files have embedded nulls, which screws everything
# up.  Here's a method that overrides to_i, to_s, and to_f to fix this up.

module Spreadsheet
  module ParseExcel
    class Worksheet
      class Cell
        def to_s ; @value.to_s.gsub("\x00",'') ; end
        def to_i ; @value.to_s.gsub("\x00",'').to_i ; end
        def to_f ; @value.to_s.gsub("\x00",'').to_f ; end
      end
    end
  end
end
