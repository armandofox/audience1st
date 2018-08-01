require 'rails_helper'

describe Show do

  it "should be searchable case-insensitive" do
    @s = create(:show, :name => "The Last Five Years")
    Show.find_unique(" the last FIVE Years").should == @s
  end
  specify "revenueper seat should be zero (not exception) if zero vouchers sold" do
    @s = create(:show)
    lambda { @s.revenue_per_seat }.should_not raise_error
    @s.revenue_per_seat.should be_zero
  end
  describe "adjusting showdates post-hoc" do
    before :each do
      @s = create(:show, :opening_date => Time.current, :closing_date => 1.day.from_now)
      @now = Time.current
      dates_and_tix = [
        [@now+1.day,  10],
        [@now,        5],
        [@now+2.days, 12],
        [@now+5.days, 0],
        [@now+3.days, 0]
      ]
      dates_and_tix.map do |params|
        sd = create(:showdate, :show => @s, :date => params[0])
        create_list(:revenue_voucher, params[1], :showdate => sd)
      end
      @s.adjust_metadata_from_showdates
    end
    it "should not change house cap" do
      @s.house_capacity_changed?.should_not be_truthy
    end
    it "should set opening date" do
      @s.opening_date.should == @now.to_date
    end
    it "should set closing date" do
      @s.closing_date.should == (@now+5.days).to_date
    end
  end
end
