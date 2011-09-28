require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include BasicModels

describe Show do

  describe "finding unique" do
    before(:each) do
      @s = BasicModels.create_generic_show("The Last Five Years")
    end
    it "should match case-insensitive" do
      Show.find_unique(" the last FIVE Years").should == @s
    end
  end

  describe "revenue" do
    it "per seat should be zero (not exception) if zero vouchers sold" do
      @s = BasicModels.create_generic_show("Show")
      lambda { @s.revenue_per_seat }.should_not raise_error
      @s.revenue_per_seat.should be_zero
    end
  end
  
  describe "adjusting showdates post-hoc" do
    before :each do
      @now = Time.now.to_date
      dates_and_tix = [
        [@now+1.day,  100],
        [@now,        50],
        [@now+2.days, 125],
        [@now+5.days, 0],
        [@now+3.days, 0]
      ]
      @s = BasicModels.create_generic_show("Show")
      @showdates = dates_and_tix.map do |params|
        mock_model(Showdate,
          :thedate => params[0],
          :vouchers => Array.new(params[1]))
      end
      @s.stub!(:showdates).and_return(@showdates)
      @s.adjust_metadata_from_showdates
    end
    it "should not change house cap" do
      @s.house_capacity_changed?.should_not be_true
    end
    it "should set opening date" do
      @s.opening_date.should == @now
    end
    it "should set closing date" do
      @s.closing_date.should == @now+5.days
    end
  end
end
