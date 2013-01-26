require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VouchertypesHelper do
  include StubUtils
  describe "seasons helper when it's 2009 season" do
    before(:each) do ; Time.stub!(:this_season).and_return(2009) ; end
    context "should work with either a range or deltas" do
      before(:each) do ; stub_month_and_day(9,1) ; end
      it "with default selection" do
        helper.options_for_seasons_range(-2,1).should ==
          helper.options_for_seasons(2007, 2010)
      end
      it "with explicit nondefault selection" do
        helper.options_for_seasons_range(-2,1,2008).should ==
          helper.options_for_seasons(2007, 2010, 2008)
      end
    end
    context "when season starts May or earlier" do
      before(:each) do
        stub_month_and_day(5,31)
      end
      it "should show season as single year" do
        @list = helper.options_for_seasons_range(-1,0)
        @list.should have_tag('option',:text => '2008')
        @list.should have_tag('option',:text => '2009')
      end
      it "should select current season" do
        @list = helper.options_for_seasons_range(-1,0)
        @list.should have_tag('option', :text => '2009', :selected => 'selected')
      end
    end
    context "when it starts June or later" do
      before(:each) do
        stub_month_and_day(6,1)
        @list = helper.options_for_seasons_range(-1,0)
      end
      it "should show season as hyphenated year" do
        @list.should have_tag('option', :text => '2008-2009')
        @list.should have_tag('option', :text => '2009-2010')
      end
      it "should select current season" do
        @list.should have_tag('option', :text => '2009-2010', :selected => 'selected')
      end
    end
    it "should not care about order of arguments" do
      stub_month_and_day(1,1)
      helper.options_for_seasons_range(-2,1).should == helper.options_for_seasons_range(1,-2)
    end
  end        
end
