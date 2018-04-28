require 'rails_helper'

describe Report do
  describe 'workaround parsing bug in Rack or Rails for multi-select box' do
    it "should handle ['3','4','5']" do
      Report.list_of_ints_from_multiselect( ['3','4','5'] ).should == [3,4,5]
    end
    it "should handle ['3,4,5']" do
      Report.list_of_ints_from_multiselect( ['3,4,5'] ).should == [3,4,5]
    end
    it "should handle ['3']" do
      Report.list_of_ints_from_multiselect( ['3'] ).should == [3]
    end
    it "should handle empty array" do
      Report.list_of_ints_from_multiselect([]).should == []
    end
    it "should handle nil" do
      Report.list_of_ints_from_multiselect(nil).should == []
    end
    it "should omit zeros" do
      Report.list_of_ints_from_multiselect(['3,0,4,5']).should == [3,4,5]
    end
  end
end
  
    
