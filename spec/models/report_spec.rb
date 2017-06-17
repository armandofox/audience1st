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
  
  describe "SQL query for constraint" do
    describe "a valid SQL query", :shared => true do
      it "should be valid SQL" do
        lambda { @r.execute_query }.should_not raise_error
      end
      it "should be an array plus bind variables" do
        @r.query.should be_an(Array)
      end
    end
    describe "with no constraints" do
      it_should_behave_like "a valid SQL query"
      before(:each) do ; @r = Report.new ; end
      it "should have no bind slots" do
        @r.query.should have(1).element
      end
      it "should dump the whole customers table" do
        @r.query.first.should match(/where\s+1\b/i)
      end
    end
  end
  describe "with output options" do
    describe "filtering by a single Zip code" do
      before(:each) do
        @r = Report.new(:filter_by_zip => "1", :zip_glob => "945")
      end
      it_should_behave_like "a valid SQL query"
      it "should generate a single LIKE constraint" do
        @r.query.first.should match(/like/i)
        @r.query.first.should_not match(/like.*like/i)
      end
      it "should generate an array with one bind slot" do
        @r.query.should have(2).elements
      end
      it "should fill the single bind slot correctly" do
        @r.query[1].should match(/945%/)
      end
    end
    describe "specifying zip code but not opting to use it" do
      it "should not apply the zip code filter" do
        @r = Report.new(:zip_glob => "945")
        @r.query.first.should_not match(/945%/)
      end
    end
    describe "filtering by multiple Zip codes" do
      before(:each) do
        @r = Report.new(:filter_by_zip => "1", :zip_glob => "945,92")
      end
      it_should_behave_like "a valid SQL query"
      it "should generate two bind slots" do
        @r.query.should have(3).elements
      end
      it "should fill in the bind slots correctly" do
        @r.query[1].should match(/945%/)
        @r.query[2].should match(/92%/)
      end
    end
    describe "setting exclude_blacklist" do
      before(:each) do ; @r = Report.new ; end
      it_should_behave_like "a valid SQL query"
      it "to true should specify e_blacklist = 0" do
        @r.output_options[:exclude_e_blacklist] = true
        @r.query.first.should match(/e_blacklist\s*=\s*0\b/i)
      end
      it "to false should specify e_blacklist = 1" do
        @r.output_options[:exclude_e_blacklist] = nil
        @r.query.first.should match(/e_blacklist\s*=\s*1\b/i)
      end
      it "if omitted should not try to match on e_blacklist" do
        @r.query.first.should_not match(/e_blacklist/i)
      end
    end
    describe "setting a nonexistent output option" do
      it "should be silently ignored" do
        @r = Report.new(:nonexistent_option => 1)
        lambda { @r.execute_query }.should_not raise_error
      end
    end
  end
end
  
    
