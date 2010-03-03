require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Showdate do
  describe "of next show" do
    context "when there are no showdates" do
      it "should be nil" do
        Showdate.current_or_next.should be_nil
      end
      it "should not raise an exception" do
        lambda { Showdate.current_or_next }.should_not raise_error
      end
    end
    context "when there is only 1 showdate and it's in the past" do
      it "should return nil" do
        @showdate  = Showdate.create!(:thedate => Time.now - 1.day)
        Showdate.current_or_next.should be_nil
      end
    end
    context "when there are past and future showdates" do
      before :each do
        @past_show = Showdate.create!(:thedate => Time.now - 1.day)
        @show_in_1_hour = Showdate.create!(:thedate => Time.now + 1.hour)
      end
      it "should return the next showdate" do
        @now_show = Showdate.create!(:thedate => Time.now + 5.minutes)
        Showdate.current_or_next.id.should == @now_show.id
      end
      it "and 30-minute margin should return a showdate that started 5 minutes ago" do
        @now_show = Showdate.create!(:thedate => Time.now - 5.minutes)
        Showdate.current_or_next(30.minutes).id.should == @now_show.id
      end
    end
  end
  describe "computing" do
    before(:each) do
      @house_cap = 12
      @max_sales = 10
      @thedate = Time.now
      @showdate = Showdate.create!(
        :thedate => @thedate,
        :end_advance_sales => @thedate - 5.minutes,
        :max_sales => @max_sales,
        :show => mock_model(Show, :valid? => true, :house_capacity => @house_cap))
      @vouchers = {
        :subscriber => 4,
        :comp => 3,
        :revenue => 2,
      }
      @nonticket_vouchers = {
        :nonticket => 1
      }
      @total_sold = @vouchers.values.inject(0) { |sum,n| sum + n }
      (@vouchers.merge(@nonticket_vouchers)).each_pair do |type,qty|
        qty.times do
          @showdate.vouchers.create!(:category => type,
            :vouchertype => mock_model(Vouchertype, :category => type),
            :purchasemethod => mock_model(Purchasemethod))
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
          v.stub!(:price).and_return(11.00)
        end
      end
      it "should be based on total seats sold" do
        # based on selling 9 seats
        @showdate.revenue.should == 99.00
      end
      it "should not include nonticket revenue" do
        @v = Voucher.new_from_vouchertype(
          Vouchertype.create!(:category => :nonticket, :price => 22,
            :name => 'fee', :account_code => '8888',
            :valid_date => Time.now - 1.month,
            :expiration_date => Time.now + 1.month))
        @v.purchasemethod = mock_model(Purchasemethod)
        @v.reserve(@showdate, mock_model(Customer))
        @v.save!
        @showdate.revenue.should ==  99.00
      end
      it "should never allow max sales to exceed house capacity" do
        @showdate.show.stub!(:house_capacity).and_return(5)
        @showdate.max_allowed_sales.should == 5
      end
      it "when max_sales not set should default to house capacity" do
        @showdate.show.stub!(:house_capacity).and_return(9)
        @showdate.update_attribute(:max_sales, 0)
        @showdate.max_allowed_sales.should == 9
      end
    end
    describe "capacity computations" do
      describe "for normal sales", :shared => true do
        # house cap 12, max sales 10, sold 9
        it "should compute total sales" do
          @showdate.compute_total_sales.should == @total_sold
          @showdate.compute_advance_sales.should == @total_sold
        end
        it "should compute total seats left" do
          @showdate.total_seats_left.should == 3
        end
        it "should not be affected by nonticket vouchers" do
          @v = Voucher.new_from_vouchertype(
            Vouchertype.create!(:category => :nonticket, :price => 99,
              :name => 'fee', :account_code => '8888',
              :valid_date => Time.now - 1.month,
              :expiration_date => Time.now + 1.month))
          @v.purchasemethod = mock_model(Purchasemethod)
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
        it "should never allow max sales to exceed house capacity" do
          @showdate.show.stub!(:house_capacity).and_return(5)
          @showdate.max_allowed_sales.should == 5
        end
        it "when max_sales not set should default to house capacity" do
          @showdate.show.stub!(:house_capacity).and_return(9)
          @showdate.update_attribute(:max_sales, 0)
          @showdate.max_allowed_sales.should == 9
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
              :vouchertype => mock_model(Vouchertype, :category => 'revenue'),
              :purchasemethod => mock_model(Purchasemethod))
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
