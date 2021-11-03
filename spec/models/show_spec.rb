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
  describe 'sorts', focus: true do
    before(:each) do
      @s1 = create(:show, :name => 'D')
      create(:showdate, :show => @s1, :thedate => 2.days.from_now)
      @s2 = create(:show, :name => 'C')
      @s3 = create(:show, :name => 'B')
      create(:showdate, :show => @s3, :thedate => 1.day.from_now)
      @s4 = create(:show, :name => 'A')
    end
    it 'shows with showdates by showdate' do
      shows = Show.where(:id => [@s1.id, @s3.id]) 
      expect(shows.sorted).to eq [@s3,@s1]
      expect(shows).to eq [@s1,@s3]
    end
    it 'shows without showdates by name' do
      shows = Show.where(:id => [@s2.id, @s4.id])
      expect(shows).to eq [@s2,@s4]
      expect(shows.sorted).to eq [@s4,@s2]
    end
    it 'shows with showdates before shows without showdates' do
      shows = Show.all
      expect(shows).to eq [@s1,@s2,@s3,@s4]
      expect(shows.sorted).to eq [@s3,@s1,@s4,@s2]
    end
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
