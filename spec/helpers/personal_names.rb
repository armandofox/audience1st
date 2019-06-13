require 'rails_helper'

# The name functions being tested here are currently included by extending
# String - although they shouldn't be.

describe "name splitting" do
  @cases = [
    "John Smith",               "John", "Smith",
    "  John    Smith  ",        "John", "Smith",
    "Gustav Mies van der Rohe", "Gustav Mies", "van der Rohe",
    "Ludwig von Beethoven",     "Ludwig", "von Beethoven",
    "Arvind",                   "", "Arvind",
    "Mary Ann Smith",           "Mary Ann", "Smith",
  ]
  @cases.each_slice(3) do |name|
    it "should split '#{name[0]}' into '#{name[1]}' and '#{name[2]}'" do
      full = name.shift
      expect(full.first_and_last_from_full_name).to eq(name)
    end
  end
end
    
