require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Showdate do
  describe "capacity computations" do
    before(:each) do
      @house_cap = 12
      @max_sales = 10
      @thedate = Time.now
      @vouchers = {:subscriber => 4,
        :comp => 3,
        :revenue => 2
      }
      @total_sold = @vouchers.values.inject(0) { |sum,n| sum + n }
      @showdate = Showdate.create!(:thedate => @thedate,
                                   :end_advance_sales => @thedate - 5.minutes,
                                   :max_sales => @max_sales,
                                   :show => mock_model(Show, :valid? => true, :house_capacity => @house_cap))
      @vouchers.each_pair do |type,qty|
        qty.times do
          @showdate.vouchers.create!(:category => type,
                                     :vouchertype => mock_model(Vouchertype, :category => type),
                                     :purchasemethod => mock_model(Purchasemethod))
        end
      end
    end
    describe "for normal sales", :shared => true do
      it "total sales" do
        @showdate.compute_total_sales.should == @total_sold
        @showdate.compute_advance_sales.should == @total_sold
      end
      it "total seats left" do
        @showdate.total_seats_left.should == @house_cap - @total_sold
      end
      it "percent sold" do
        @showdate.percent_sold.should == (@total_sold.to_f / @house_cap) * 100
      end
    end
    describe "when house is partly sold" do
      it_should_behave_like "for normal sales"
    end
    describe "when house is oversold" do
      before(:each) do
        (@house_cap - @total_sold + 2).times do
          @showdate.vouchers.create!(:category => 'revenue',
                                     :vouchertype => mock_model(Vouchertype, :category => 'revenue'),
                                     :purchasemethod => mock_model(Purchasemethod))
        end
      end
      it "should show as 100 percent sold (not more)" do
        @showdate.percent_sold.should == 100.0
      end
      it "should show zero (not negative) seats remaining" do
        @showdate.total_seats_left.should == 0
      end
    end
    describe "when sold beyond max sales but not house" do
      before(:each) do
        @showdate.update_attribute(:max_sales, 8)
      end
      it_should_behave_like "for normal sales"
    end
  end
end

