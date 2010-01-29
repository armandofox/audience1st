require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cart do
  before(:each) do
    @cart = Cart.new
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

      
