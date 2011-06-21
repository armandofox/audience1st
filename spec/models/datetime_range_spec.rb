require 'spec_helper'

describe DatetimeRange do

  describe "attributes" do
    before(:each) do ;  @d = DatetimeRange.new ; end
    it "has a start date" do ;   @d.start_date.should be_a(Date)  ; end
    it "has an end date"  do ;   @d.end_date.should be_a(Date) ; end
    it "has a time" do ; @d.time.should be_a(Time) ; end
    context "are invalid" do
      it "if days of week not in range 0-6" do
        lambda { DatetimeRange.new(:days_of_week => [8]) }.should raise_error(ArgumentError)
      end
      it "if days of week is not an array" do
        lambda { DatetimeRange.new(:days_of_week => 3) }.should raise_error(ArgumentError)
      end
    end
  end

  describe "counting dates" do
    context "over less than 1 week" do
      before(:each) do
        @range = DatetimeRange.new(
          :start_date => Date.parse("2011-07-31"),
          :end_date => Date.parse("2011-08-07"),
          :time => Time.parse("6:30pm"),
          :days_of_week => [0,2,4])
        @dates = @range.dates
      end
      it "should result in a list of Time objects" do
        @dates.first.should be_a(Time)
      end
      it "should return correct count" do
        @range.count.should == 4
      end
      it "should include boundary dates" do
        @dates.should have(4).elements
      end
      it "should set the time correctly" do
        @dates.each do |d|
          d.hour.should == 18
          d.min.should == 30
        end
      end
    end
    context "over Feb 29 on a leap year" do
      before(:each) do
        @range = DatetimeRange.new(
          :start_date => Date.parse("2012-02-25"), :end_date => Date.parse("2012-03-02"),
          :time => Time.parse("12:00 pm"),
          :days_of_week => [0,1,2,3,4,5,6])
      end
      it "should count correctly" do ; @range.count.should == 7 ; end
      it "should include Feb 29" do
        @range.dates.should include(Time.parse("Feb 29, 2012, 12:00pm"))
      end
    end
    it "should work correctly when no dates included" do
      DatetimeRange.new(
        :start_date => Date.today, :end_date => Date.today+11.days,
        :days_of_week => []).dates.should be_empty
    end
  end

end
