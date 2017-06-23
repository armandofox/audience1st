require 'rails_helper'

describe "Date/time extras" do
  def stub_month_and_day(month,day)
    allow(Option).to_receive(:season_start_month).and_return(month)
    allow(Option).to_receive(:season_start_day).and_return(day)
  end    
  describe "season calculations" do
    context "for season 1/1/09 - 12/31/09" do
      before(:each) do
        stub_month_and_day(1,1)
        @now = Time.local(2009,2,1)
      end
      it "should compute beginning of season" do
        @now.at_beginning_of_season.should == Time.local(2009,1,1)
      end
      it "should compute end of season" do
        @now.at_end_of_season.to_date.should == Date.civil(2009,12,31)
      end
      it "should include first day of season" do
        Date.civil(2009,1,1).within_season?(2009).should be_true
      end
      it "should include last day of season is part of the season" do
        Date.civil(2009,12,31).within_season?(2009).should be_true
      end
      it "should NOT include a date in next season" do
        Date.civil(2010,1,1).within_season?(2009).should be falsey
      end
      it "should NOT include a date in past season" do
        Date.civil(2008,1,1).within_season?(2009).should be falsey
      end
      it "should compute current season year" do
        @now.this_season.should == 2009
      end
    end
    context "for previous seasons" do
      before(:each) do
        @m, @d = 2,5
        stub_month_and_day(@m, @d)
      end
      it "should calculate the beginning of the 2005 season" do
        Time.now.at_beginning_of_season(2005).should == Time.local(2005,@m,@d)
      end
      it "should calculate the end of the 2005 season" do
        Time.now.at_end_of_season(2005).should == (Time.local(2006,@m,@d,23,59,59) - 1.day)
      end
      it "should calculate beginning of current season when calendar date precedes season start date" do
        y = Time.now.year
        Time.local(y, @m, @d-1).at_beginning_of_season.should == Time.local(y-1,@m,@d)
      end
      it "should calculate beginning of current season when calendar date is after season start date" do
        y = Time.now.year
        Time.local(y, @m, @d+1).at_beginning_of_season.should == Time.local(y,@m,@d)
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
        d.at_beginning_of_season.should == d.at_beginning_of_season(2009)
      end
      it "should compute beginning of season for a date in this year" do
        (@start + 1.day).at_beginning_of_season.should == @start
      end
      it "should compute beginning of season for a date in next year" do
        (@end - 1.day).at_beginning_of_season.should == @start
      end
      it "should compute end of season for a date in this year" do
        (@start + 1.day).at_end_of_season.should == @end
      end
      it "should compute end of season for a date in next year" do
        (@end - 1.day).at_end_of_season.should == @end
      end
      it "should exclude a date that is within next calendar year but not season" do
        (@end + 1.day).within_season?(2009).should be falsey
      end
      it "should exclude a date that is within this calendar year but not season" do
        (@start - 1.day).within_season?(2009).should be falsey
      end
      it "should include a date that is this calendar year and season" do
        (@start + 1.day).within_season?(2009).should be_true
      end
      it "should include a date that is next calendar year and in season" do
        (@end - 1.day).within_season?(2009).should be_true
      end
    end
    describe "should give same result for date or time object" do
      before(:each) do
        stub_month_and_day(9,1)
        @time = Time.parse("2011-01-21")
        @date = Date.civil(2011, 1, 21)
      end
      it "if different year" do
        @time.at_beginning_of_season.to_date.should == @date.at_beginning_of_season
      end
      it "if year given explicitly" do
        @time.at_beginning_of_season(2008).to_date.should ==
          @date.at_beginning_of_season(2008)
      end
      it "going the other way - different year" do
        @date.at_beginning_of_season.to_time.should ==
          @time.at_beginning_of_season
      end
      it "going the other way - explicit year" do
        @date.at_beginning_of_season(2008).to_time.should ==
          @time.at_beginning_of_season(2008)
      end
    end
  end

  describe "creating a date or time from params[]" do
    it "should return default value if param is blank" do
      deflt = Time.now
      Time.from_param(nil,deflt).should == deflt
    end
    context "when param is not a hash" do
      it "should parse if given a string" do
        str = "February 3, 2008, 8:15PM"
        Time.from_param(str).should == Time.local(2008,2,3,20,15)
      end
      it "should raise an exception if given garbage" do
        lambda {
          Time.from_param("00")
        }.should raise_error
      end
    end
    context "when param is a hash" do
      before(:each) do
        @h = {:year=>2008, :month=>1, :day=>2}
      end
      it "should parse a hash containing only date info" do
        Time.from_param(@h).should == Time.local(2008,1,2,0,0,0)
      end
      it "should parse a hash containing date and hour" do
        Time.from_param(@h.merge({:hour => 17})).should ==
          Time.local(2008,1,2,17,0,0)
      end
      it "should parse a hash containing date, hour and minute" do
        Time.from_param(@h.merge({:hour => 17,:minute => 3})).should ==
          Time.local(2008,1,2,17,3,0)
      end
    end
  end
end
