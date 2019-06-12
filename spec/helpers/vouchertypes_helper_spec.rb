require 'rails_helper'

describe VouchertypesHelper do
  def stub_month_and_day(month,day)
    Option.first.update_attributes!(:season_start_month => month, :season_start_day => day)
  end
  describe "seasons helper when it's 2009 season" do
    before(:each) do ; allow(Time).to receive(:this_season).and_return(2009) ; end
    context "should work with either a range or deltas" do
      before(:each) do ; stub_month_and_day(9,1) ; end
      it "with default selection" do
        expect(helper.options_for_seasons_range(-2,1)).to eq(
          helper.options_for_seasons(2007, 2010)
        )
      end
      it "with explicit nondefault selection" do
        expect(helper.options_for_seasons_range(-2,1,2008)).to eq(
          helper.options_for_seasons(2007, 2010, 2008)
        )
      end
    end
    context "when season starts May or earlier" do
      before(:each) do
        stub_month_and_day(5,31)
      end
      it "should show season as single year" do
        @list = helper.options_for_seasons_range(-1,0)
        expect(@list).to have_tag('option',:text => '2008')
        expect(@list).to have_tag('option',:text => '2009')
      end
      it "should select current season" do
        @list = helper.options_for_seasons_range(-1,0)
        expect(@list).to have_tag('option', :text => '2009', :selected => 'selected')
      end
    end
    context "when it starts June or later" do
      before(:each) do
        stub_month_and_day(6,1)
        @list = helper.options_for_seasons_range(-1,0)
      end
      it "should show season as hyphenated year" do
        expect(@list).to have_tag('option', :text => '2008-2009')
        expect(@list).to have_tag('option', :text => '2009-2010')
      end
      it "should select current season" do
        expect(@list).to have_tag('option', :text => '2009-2010', :selected => 'selected')
      end
    end
    it "should not care about order of arguments" do
      stub_month_and_day(1,1)
      expect(helper.options_for_seasons_range(-2,1)).to eq(helper.options_for_seasons_range(1,-2))
    end
  end        
end
