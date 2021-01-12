require 'rails_helper'

describe Show do

  it "should be searchable case-insensitive" do
    @s = create(:show, :name => "The Last Five Years")
    expect(Show.find_unique(" the last FIVE Years")).to eq(@s)
  end
  specify "revenue per seat should be zero (not exception) if zero vouchers sold" do
    @s = create(:show)
    expect { @s.revenue_per_seat }.not_to raise_error
    expect(@s.revenue_per_seat).to be_zero
  end
  describe 'opening and closing dates' do
    before(:each) do
      @list = 2.days.from_now.to_date
      @s = create(:show, :listing_date => @list)
    end
    specify 'match listing date if no showdates' do
      expect(@s.opening_date).to eq(@list)
      expect(@s.closing_date).to eq(@list)
    end
    specify 'match listing date if no PERSISTED showdates' do
      @s.showdates.build(:thedate => 3.days.from_now)
      @s.showdates.build(:thedate => 4.days.from_now)
      expect(@s.opening_date).to eq(@list)
      expect(@s.closing_date).to eq(@list)
    end
    specify 'match when only 1 performance' do
      thedate = 3.days.from_now
      create(:showdate, :show => @s, :thedate => thedate)
      expect(@s.opening_date).to eq(thedate.to_date)
      expect(@s.closing_date).to eq(thedate.to_date)
    end
    specify 'match when multiple performances' do
      open,close = 3.days.from_now, 5.days.from_now
      create(:showdate, :show => @s, :thedate => open)
      create(:showdate, :show => @s, :thedate => close)
      expect(@s.opening_date).to eq(open.to_date)
      expect(@s.closing_date).to eq(close.to_date)
    end
  end
end
