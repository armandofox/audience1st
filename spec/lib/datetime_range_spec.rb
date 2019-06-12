require 'rails_helper'

describe DatetimeRange do

  describe "attributes" do
    before(:each) do ;  @d = DatetimeRange.new ; end
    it "has a start date" do ;   expect(@d.start_date).to be_a(Date)  ; end
    it "has an end date"  do ;   expect(@d.end_date).to be_a(Date) ; end
    it "converts strings to ints if needed" do
      expect(DatetimeRange.new(:days => ['3', 4, '6.0']).days).to eq([3,4,6])
    end
    it "should be invalid if days of week not in range 0-6" do
      expect { DatetimeRange.new(:days => [8]) }.to raise_error(ArgumentError)
    end
  end

  describe "counting dates" do
    context "over less than 1 week" do
      before(:each) do
        @range = DatetimeRange.new(
          :start_date => Date.parse("2011-07-31"), # sunday
          :end_date => Date.parse("2011-08-07"),   # also sunday
          :hour => 18, :minute => '30',
          :days => [0,2,4]) # sunday, tuesday, thursday
        @dates = @range.dates
      end
      it "should result in a list of Time objects" do
        expect(@dates.first).to be_a(Time)
      end
      it "should return correct count" do
        expect(@range.count).to eq(4)
      end
      it "should include boundary dates" do
        expect(@dates.size).to eq(4)
      end
      it "should set the time correctly" do
        @dates.each do |d|
          expect(d.hour).to eq(18)
          expect(d.min).to eq(30)
        end
      end
      it "should compute the right datetimes in the local timezone" do
        t = Time.zone
        result = ["2011-07-31 18:30",
          "2011-08-02 18:30",
          "2011-08-04 18:30",
          "2011-08-07 18:30"].each do |l|
          expect(@dates).to include(Time.zone.parse l)
        end
      end
    end
    context "over Feb 29 on a leap year" do
      before(:each) do
        @range = DatetimeRange.new(
          :start_date => Date.parse("2012-02-25"), :end_date => Date.parse("2012-03-02"),
          :hour => 12,
          :days => [0,1,2,3,4,5,6])
      end
      it "should count correctly" do ; expect(@range.count).to eq(7) ; end
      it "should include Feb 29" do
        expect(@range.dates).to include(Time.zone.parse("Feb 29, 2012, 12:00pm"))
      end
    end
    it "should work correctly when no dates included" do
      expect(DatetimeRange.new(
        :start_date => Date.today, :end_date => Date.today+11.days,
        :days => []).dates).to be_empty
    end
  end

end
