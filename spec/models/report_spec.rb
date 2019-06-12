require 'rails_helper'

describe Report do
  describe 'workaround parsing bug in Rack or Rails for multi-select box' do
    it "should handle ['3','4','5']" do
      expect(Report.list_of_ints_from_multiselect( ['3','4','5'] )).to eq([3,4,5])
    end
    it "should handle ['3,4,5']" do
      expect(Report.list_of_ints_from_multiselect( ['3,4,5'] )).to eq([3,4,5])
    end
    it "should handle ['3']" do
      expect(Report.list_of_ints_from_multiselect( ['3'] )).to eq([3])
    end
    it "should handle empty array" do
      expect(Report.list_of_ints_from_multiselect([])).to eq([])
    end
    it "should handle nil" do
      expect(Report.list_of_ints_from_multiselect(nil)).to eq([])
    end
    it "should omit zeros" do
      expect(Report.list_of_ints_from_multiselect(['3,0,4,5'])).to eq([3,4,5])
    end
  end
end
  
    
