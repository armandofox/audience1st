require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cart do
  before(:each) do
    @cart = Cart.new
  end
  describe "performance dates info" do
    before(:each) do
      @date1 = Time.parse("January 3, 2011, 7:30pm")
      @date2 = Time.parse("March 1, 2012, 6:00pm")
      @sd1 = BasicModels.create_one_showdate(@date1)
      @sd2 = BasicModels.create_one_showdate(@date2)
    end
    it "should show date of performance if only one performance" do
      @cart.add(mock("fake_voucher", :showdate => @sd1, :price => 15))
      @cart.double_check_dates.should == @date1.to_formatted_s(:showtime)
    end
    it "should show date of performance if multiple items with same date" do
      @cart.add(mock("fake_voucher1", :showdate => @sd1, :price => 15))
      @cart.add(mock("fake_voucher2", :showdate => @sd1, :price => 15))
      @cart.double_check_dates.should == @date1.to_formatted_s(:showtime)
    end
    it "should be empty if no items with dates in cart" do
      @cart.double_check_dates.should == ''
    end
    it "should show multiple dates if items with different dates" do
      @cart.add(mock("fake_voucher1", :showdate => @sd1, :price => 15))
      @cart.add(mock("fake_voucher2", :showdate => @sd2, :price => 15))
      @cart.add(mock("fake_voucher3", :showdate => @sd1, :price => 15))
      @cart.double_check_dates.should ==
        "#{@date1.to_formatted_s(:showtime)} and #{@date2.to_formatted_s(:showtime)}"
    end
    it "should not barf for vouchers with no showdate" do
      @cart.add(mock("sub_voucher", :showdate => nil, :price => 88))
      lambda { @cart.double_check_dates }.should_not raise_error
      @cart.double_check_dates.should be_blank
    end
  end
  it "should not return same order ID twice" do
    o1 = Cart.generate_order_id
    o2 = Cart.generate_order_id
    o1.should_not == o2
  end
  it "should retain order ID once set for cart" do
    c1 = @cart.order_number
    c2 = @cart.order_number
    c1.should == c2
  end
  context "when empty" do
    it "should contain no vouchers" do
      @cart.include_vouchers?.should be_nil
    end
    it "should contain no donations" do
      @cart.include_donation?.should be_nil
    end
    it "should be empty" do
      @cart.should be_empty
    end
  end
  describe "adding" do
    describe "donation" do
      before(:each) do
        @donation = mock_model(Donation, :amount => 13.00, :price => 13.00)
        @cart.add(@donation)
      end
      it "should include the donation" do
        @cart.include_donation?.should be_true
      end
      it "should have a total value of the donation's value" do
        @cart.total_price.should == @donation.amount
      end
    end
  end
end

      
