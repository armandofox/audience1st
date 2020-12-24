require 'rails_helper'

describe Showdate do
  describe "season calculation", focus: true do
    before(:each) do ; @t = Time.this_season ; end
    it 'returns this season if no shows or showdates' do
      expect(Showdate.seasons_range).to eq([@t,@t])
    end
    it 'works if exactly one showdate' do
      sd = create(:showdate)
      t = sd.show.season
      expect(Showdate.seasons_range).to eq([t,t])
    end
    context 'works for multiple shows' do
      before(:each) do
        @s = create(:show)
        @s2 = create(:show)
      end
      specify 'if not all have showdates' do
        sd2 = create(:showdate, :show => @s2, :thedate => 2.years.from_now)
        expect(Showdate.seasons_range).to eq([@t,@t+2])
      end
      specify 'if none have showdates' do
        expect(Showdate.seasons_range).to eq([@t,@t])
      end
      specify 'if both have showdates' do
        sd1 = create(:showdate, :show => @s, :thedate => 1.year.ago)
        sd1 = create(:showdate, :show => @s2, :thedate => 1.year.from_now)
        expect(Showdate.seasons_range).to eq([@t-1,@t+1])
      end
    end
  end
  describe "house capacity" do
    before(:each) do
      @s = build(:showdate)
    end
    describe "for General Admission" do
      it "must be specified" do
        @s.update_attributes!(:house_capacity => 73)
        expect(@s.house_capacity).to eq(73)
      end
    end
    describe "for Reserved Seating" do
      before(:each) do
        @s.seatmap = create(:seatmap) # default for testing has 4 seats
      end
      it "is valid even if numerical field is zero" do
        @s.house_capacity = 0
        expect(@s).to be_valid
      end
      it "overrides static value" do
        @s.update_attributes!(:house_capacity => 100)
        expect(@s.house_capacity).to eq(4)
      end
    end
  end
  describe "can have only one stream-anytime performance" do
    before(:each) do
      @d1 = create(:stream_anytime_showdate)
      @next = @d1.thedate + 1.day
    end
    specify 'normally' do
      d2 = build(:stream_anytime_showdate, :show => @d1.show, :thedate => @next)
      expect(d2).not_to be_valid
      expect(d2.errors[:base]).not_to be_blank
    end
    specify 'but live streams are OK' do
      d2 = build(:live_stream_showdate, :show => @d1.show, :thedate => @next)
      expect(d2).to be_valid
    end
  end
  
  describe "availability grade" do
    before(:each) do
      @sd = create(:showdate)
      allow(@sd).to receive(:percent_sold).and_return(70)
    end
    cases = {
      [20,50] => 1,          # nearly sold out
      [20,70] => 1,          # nearly sold out - boundary cond
      [20,90] => 2,          # limited avail
      [75,80] => 3
    }
    cases.each do |c,grade|
      specify "with thresholds #{c.join ','}" do
        Option.first.update_attributes(
          :limited_availability_threshold => c[0],
          :nearly_sold_out_threshold => c[1])
        expect(@sd.availability_grade).to eq(grade)
      end
    end
  end
  describe "of next show" do
    context "for non-regular shows" do
      it 'returns correct entry' do
        regular = create(:show, :event_type => 'Regular Show')
        special = create(:show, :event_type => 'Special Event')
        s1 = create(:showdate, :show => regular, :thedate => 1.day.from_now)
        s2 = create(:showdate, :show => special, :thedate => 2.days.from_now)
        expect(Showdate.current_or_next(:type => 'Special Event').id).to eq(s2.id)
      end
      it 'returns nil if no matches' do
        s1 = create(:showdate)
        expect(Showdate.current_or_next(:type => 'Special Event')).to be_nil
      end
    end
    
    context "when there are no showdates" do
      before(:each) do ; Showdate.delete_all ; end
      it "should be nil" do
        expect(Showdate.current_or_next).to be_nil
      end
      it "should not raise an exception" do
        expect { Showdate.current_or_next }.not_to raise_error
      end
    end
    context "when there is only 1 showdate and it's in the past" do
      it "should return that showdate" do
        @showdate  = create(:showdate, :thedate => 1.day.ago)
        expect(Showdate.current_or_next.id).to eq(@showdate.id)
      end
    end
    context "when there are past and future showdates" do
      before :each do
        @past_show = create(:showdate, :thedate => 1.day.ago)
        @show_in_1_hour = create(:showdate, :thedate => 1.hour.from_now)
      end
      it "should return the next showdate" do
        @now_show = create(:showdate, :thedate => 5.minutes.from_now)
        expect(Showdate.current_or_next.id).to eq(@now_show.id)
      end
      it "and 30-minute margin should return a showdate that started 5 minutes ago" do
        @now_show = create(:showdate, :thedate => 5.minutes.ago)
        expect(Showdate.current_or_next(:grace_period => 30.minutes).id).to eq(@now_show.id)
      end
    end
  end
end
