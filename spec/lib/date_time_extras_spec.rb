require 'rails_helper'

describe "Date/time extras" do
  def stub_month_and_day(month,day)
    Option.first.update_attributes!(:season_start_month => month, :season_start_day => day)
  end    
  describe "season calculations" do
    context "for season 1/1/09 - 12/31/09" do
      before(:each) do
        stub_month_and_day(1,1)
        @now = Time.local(2009,2,1)
      end
      it "should compute beginning of season" do
        expect(@now.at_beginning_of_season).to eq(Time.local(2009,1,1))
      end
      it "should compute end of season" do
        expect(@now.at_end_of_season.to_date).to eq(Date.civil(2009,12,31))
      end
      it "should include first day of season" do
        expect(Date.civil(2009,1,1).within_season?(2009)).to be_truthy
      end
      it "should include last day of season is part of the season" do
        expect(Date.civil(2009,12,31).within_season?(2009)).to be_truthy
      end
      it "should NOT include a date in next season" do
        expect(Date.civil(2010,1,1).within_season?(2009)).to be_falsey
      end
      it "should NOT include a date in past season" do
        expect(Date.civil(2008,1,1).within_season?(2009)).to be_falsey
      end
      it "should compute current season year" do
        expect(@now.this_season).to eq(2009)
      end
    end
    context "for previous seasons" do
      before(:each) do
        @m, @d = 2,5
        stub_month_and_day(@m, @d)
      end
      it "should calculate the beginning of the 2005 season" do
        expect(Time.current.at_beginning_of_season(2005)).to eq(Time.local(2005,@m,@d))
      end
      it "should calculate the end of the 2005 season" do
        expect(Time.current.at_end_of_season(2005)).to eq(Time.local(2006,@m,@d,23,59,59) - 1.day)
      end
      it "should calculate beginning of current season when calendar date precedes season start date" do
        y = Time.current.year
        expect(Time.local(y, @m, @d-1).at_beginning_of_season).to eq(Time.local(y-1,@m,@d))
      end
      it "should calculate beginning of current season when calendar date is after season start date" do
        y = Time.current.year
        expect(Time.local(y, @m, @d+1).at_beginning_of_season).to eq(Time.local(y,@m,@d))
      end
    end
    context "for season 9/1/09 - 8/31/10" do
      before(:each) do
        stub_month_and_day(9,1)
        @start = Time.local(2009,9,1)
        @end = Time.local(2010,8,31,23,59,59)
      end
      it "should be identified as the 2009 season" do
        d = @start + 1.day
        expect(d.at_beginning_of_season).to eq(d.at_beginning_of_season(2009))
      end
      it "should compute beginning of season for a date in this year" do
        expect((@start + 1.day).at_beginning_of_season).to eq(@start)
      end
      it "should compute beginning of season for a date in next year" do
        expect((@end - 1.day).at_beginning_of_season).to eq(@start)
      end
      it "should compute end of season for a date in this year" do
        expect((@start + 1.day).at_end_of_season).to eq(@end)
      end
      it "should compute end of season for a date in next year" do
        expect((@end - 1.day).at_end_of_season).to eq(@end)
      end
      it "should exclude a date that is within next calendar year but not season" do
        expect((@end + 1.day).within_season?(2009)).to be_falsey
      end
      it "should exclude a date that is within this calendar year but not season" do
        expect((@start - 1.day).within_season?(2009)).to be_falsey
      end
      it "should include a date that is this calendar year and season" do
        expect((@start + 1.day).within_season?(2009)).to be_truthy
      end
      it "should include a date that is next calendar year and in season" do
        expect((@end - 1.day).within_season?(2009)).to be_truthy
      end
    end
    describe "should give same result for date or time object" do
      before(:each) do
        stub_month_and_day(9,1)
        @time = Time.zone.parse("2011-01-21")
        @date = Date.civil(2011, 1, 21)
      end
      it "if different year" do
        expect(@time.at_beginning_of_season.to_date).to eq(@date.at_beginning_of_season)
      end
      it "if year given explicitly" do
        expect(@time.at_beginning_of_season(2008).to_date).to eq(
          @date.at_beginning_of_season(2008)
        )
      end
      it "going the other way - different year" do
        expect(@date.at_beginning_of_season.to_time).to eq(
          @time.at_beginning_of_season
        )
      end
      it "going the other way - explicit year" do
        expect(@date.at_beginning_of_season(2008).to_time).to eq(
          @time.at_beginning_of_season(2008)
        )
      end
    end
  end

  describe "creating a date or time from params[]" do
    it "should return default value if param is blank" do
      deflt = Time.current
      expect(Time.from_param(nil,deflt)).to eq(deflt)
    end
    context "when param is not a hash" do
      it "should parse if given a string" do
        str = "February 3, 2008, 8:15PM"
        expect(Time.from_param(str)).to eq(Time.local(2008,2,3,20,15))
      end
      it "should raise an exception if given garbage" do
        expect {
          Time.from_param("00")
        }.to raise_error(ArgumentError)
      end
    end
    context "when param is a hash" do
      before(:each) do
        @h = {:year=>2008, :month=>1, :day=>2}
      end
      it "should parse a hash containing only date info" do
        expect(Time.from_param(@h)).to eq(Time.local(2008,1,2,0,0,0))
      end
      it "should parse a hash containing date and hour" do
        expect(Time.from_param(@h.merge({:hour => 17}))).to eq(
          Time.local(2008,1,2,17,0,0)
        )
      end
      it "should parse a hash containing date, hour and minute" do
        expect(Time.from_param(@h.merge({:hour => 17,:minute => 3}))).to eq(
          Time.local(2008,1,2,17,3,0)
        )
      end
    end
  end
end
