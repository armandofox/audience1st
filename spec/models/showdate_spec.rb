require 'rails_helper'

describe Showdate do
  describe "availability grade" do
    before(:each) do
      @sd = create(:showdate)
      allow(@sd).to receive(:percent_sold).and_return(70)
    end
    cases = {
      [20,50,60] => 0,          # sold out
      [20,50,70] => 0,          # sold out -boundary cond
      [20,50,80] => 1,          # nearly sold out
      [20,70,90] => 1,          # nearly sold out - boundary cond
      [20,90,95] => 2,          # limited avail
      [75,80,90] => 3
    }
    cases.each do |c,grade|
      specify "with thresholds #{c.join ','}" do
        allow(Option).to receive(:limited_availability_threshold).and_return(c[0])
        allow(Option).to receive(:nearly_sold_out_threshold).and_return(c[1])
        allow(Option).to receive(:sold_out_threshold).and_return(c[2])
        @sd.availability_grade.should == grade
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
        Showdate.current_or_next(:type => 'Special Event').id.should == s2.id
      end
      it 'returns nil if no matches' do
        s1 = create(:showdate)
        Showdate.current_or_next(:type => 'Special Event').should be_nil
      end
    end
      
    context "when there are no showdates" do
      before(:each) do ; Showdate.delete_all ; end
      it "should be nil" do
        Showdate.current_or_next.should be_nil
      end
      it "should not raise an exception" do
        lambda { Showdate.current_or_next }.should_not raise_error
      end
    end
    context "when there is only 1 showdate and it's in the past" do
      it "should return that showdate" do
        skip 'debug'
        @showdate  = Showdate.create!(:thedate => 1.day.ago, :end_advance_sales => 1.day.ago)
        Showdate.current_or_next.id.should == @showdate.id
      end
    end
    context "when there are past and future showdates" do
      before :each do
        @past_show = create(:showdate, :thedate => 1.day.ago)
        @show_in_1_hour = create(:showdate, :thedate => 1.hour.from_now)
      end
      it "should return the next showdate" do
        @now_show = create(:showdate, :thedate => 5.minutes.from_now)
        Showdate.current_or_next.id.should == @now_show.id
      end
      it "and 30-minute margin should return a showdate that started 5 minutes ago" do
        @now_show = create(:showdate, :thedate => 5.minutes.ago)
        Showdate.current_or_next(:grace_period => 30.minutes).id.should == @now_show.id
      end
    end
  end
  describe 'max sales' do
    before :each do
      @s = create(:showdate, :date => Time.now, :max_sales => 200)
    end
    describe 'when zero' do
      before(:each) { @s.update_attributes!(:max_sales => 0) }
      it('should be allowed') {  @s.max_allowed_sales.should be_zero }
      it('should make show sold-out') { @s.should be_really_sold_out }
    end
      
  end
  describe "computing" do
    before(:each) do
      @house_cap = 12
      @max_sales = 10
      @thedate = Time.now
      @showdate = FactoryGirl.create(:showdate,
        :thedate => @thedate,
        :end_advance_sales => @thedate - 5.minutes,
        :max_sales => @max_sales)
      @showdate.show.update_attributes!(:house_capacity => @house_cap)
      @vouchers = {
        'subscriber' => 4,
        'comp' => 3,
        'revenue' => 2,
      }
      @nonticket_vouchers = {
        'nonticket' => 1
      }
      @total_sold = @vouchers.values.inject(0) { |sum,n| sum + n }
      (@vouchers.merge(@nonticket_vouchers)).each_pair do |type,qty|
        qty.times do
          @showdate.vouchers.create!(:category => type,
            :vouchertype => mock_model(Vouchertype, :category => type))
        end
      end
    end

    describe "vouchers" do
      it "should have 9 vouchers" do
        @showdate.should have(9).vouchers
      end
      it "should have 10 actual vouchers including nonticket" do
        @showdate.should have(10).all_vouchers
        (@showdate.all_vouchers - @showdate.vouchers).first.category.to_s.should == 'nonticket'
      end
    end
    describe "revenue" do
      before(:each) do
        @showdate.vouchers.each do |v|
          allow(v).to receive(:amount).and_return(11.00)
        end
      end
      it "should be based on total seats sold" do
        # based on selling 9 seats
        @showdate.revenue.should == 99.00
      end
      it "should not include nonticket revenue" do
        @v = Voucher.new_from_vouchertype(create(:nonticket_vouchertype,:price => 22))
        @v.reserve(@showdate, mock_model(Customer))
        @v.save!
        @showdate.revenue.should ==  99.00
      end
    end
    describe "capacity computations" do
      shared_examples "for normal sales" do
        # house cap 12, max sales 10, sold 9
        it "should compute total sales" do
          @showdate.compute_total_sales.should == @total_sold
          @showdate.compute_advance_sales.should == @total_sold
        end
        it "should compute total seats left" do
          @showdate.total_seats_left.should == 3
        end
        it "should not be affected by nonticket vouchers" do
          @v = Voucher.new_from_vouchertype(create(:nonticket_vouchertype, :price => 99))
          @v.reserve(@showdate, mock_model(Customer))
          @v.save!
          @showdate.total_seats_left.should == 3
        end
        it "should compute percent of max sales" do
          @showdate.percent_sold.should == ((@total_sold.to_f / @max_sales) * 100).floor
        end
        it "should compute percent of house" do
          @showdate.percent_of_house.should == ((@total_sold.to_f / @house_cap) * 100).floor
        end
      end
      describe "when house is partly sold" do
        it_should_behave_like "for normal sales"
        it "should compute saleable seats left" do
          @showdate.saleable_seats_left.should == 1
        end
      end
      describe "when house is oversold" do
        before(:each) do
          (@house_cap - @total_sold + 2).times do
            @showdate.vouchers.create!(:category => 'revenue',
              :vouchertype => mock_model(Vouchertype, :category => 'revenue'))
          end
        end
        it "should show zero (not negative) seats remaining" do
          @showdate.total_seats_left.should == 0
          @showdate.saleable_seats_left.should == 0
        end
      end
      describe "when sold beyond max sales but not house cap" do
        before(:each) do
          @max_sales = 8
          @showdate.update_attribute(:max_sales, @max_sales)
        end
        it_should_behave_like "for normal sales"
        it "should compute saleable seats left" do
          @showdate.saleable_seats_left.should == 0
        end
        it "should show zero (not negative) seats remaining" do
          @showdate.saleable_seats_left.should == 0
        end
      end
    end
  end
end
