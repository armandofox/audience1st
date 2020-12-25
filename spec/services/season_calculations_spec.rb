require 'rails_helper'

describe SeasonCalculations do
  before(:each) do
    # season starts 2 Sep
    Option.update_attributes!(:season_start_month => 9, :season_start_day => 2)
  end
  describe "season calculation" do
    before(:each) do ; @t = Time.this_season ; end
    it 'returns this season if no shows or showdates' do
      expect(SeasonCalculations.seasons_range).to eq([@t,@t])
    end
    it 'works if exactly one showdate' do
      sd = create(:showdate)
      t = sd.show.season
      expect(SeasonCalculations.seasons_range).to eq([t,t])
    end
    context 'works for multiple shows' do
      before(:each) do
        @s = create(:show)
        @s2 = create(:show)
      end
      specify 'if not all have showdates' do
        sd2 = create(:showdate, :show => @s2, :thedate => 2.years.from_now)
        expect(SeasonCalculations.seasons_range).to eq([@t,@t+2])
      end
      specify 'if none have showdates' do
        expect(SeasonCalculations.seasons_range).to eq([@t,@t])
      end
      specify 'if both have showdates' do
        sd1 = create(:showdate, :show => @s, :thedate => 1.year.ago)
        sd1 = create(:showdate, :show => @s2, :thedate => 1.year.from_now)
        expect(SeasonCalculations.seasons_range).to eq([@t-1,@t+1])
      end
    end
  end
  describe "shows during", focus: true do
    before(:each) do
      @s1 = create(:show)
      @s2 = create(:show)
      @s3 = create(:show)
      @showdates = [
        # middle of 2009 season
        create(:showdate, :thedate => Time.parse('May 8,2010, 8pm'), :show => @s1),
        # end of 2009 season, but only just
        create(:showdate, :thedate => Time.parse('Sep 1,2010, 8pm'), :show => @s1),
        # first day of 2010 season
        create(:showdate, :thedate => Time.parse('Sep 2,2010, 8pm'), :show => @s2),
        # middle of 2010 season
        create(:showdate, :thedate => Time.parse('Dec 9,2010, 8pm'), :show => @s2),
        # first day of 2011 season
        create(:showdate, :thedate => Time.parse('Sep 1,2011, 8pm') + 1.year, :show => @s3),
        # middle of 2011 season
        create(:showdate, :thedate => Time.parse('Jan 9,2012, 8pm') + 2.years, :show => @s3)
      ]
    end
    specify "this season" do
      expect(SeasonCalculations.all_shows_for_seasons(2010,2010)).to eq([@s2])
    end
    specify "last season and this season" do
      expect(SeasonCalculations.all_shows_for_seasons(2009,2010)).to eq([@s1,@s2])
    end
    specify "all seasons" do
      expect(SeasonCalculations.all_shows_for_seasons(2009,2011)).to eq([@s1,@s2,@s3])
    end
    specify "nonexistent seasons" do
      expect(SeasonCalculations.all_shows_for_seasons(2006,2008)).to be_empty
    end
  end
end
