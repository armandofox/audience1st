require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Voucher do

  before :all do
    # mock some Vouchertype objects for these tests
    @vt_regular = mock_model(RevenueVouchertype, :null_object => true)
    @vt_bundle = mock_model(BundleVouchertype, :null_object => true)
    { :fulfillment_needed => false,
      :valid_date => Time.now - 1.month,
      :expiration_date => Time.now + 1.month }.each_pair do |meth,retval|
      @vt_regular.stub!(meth).and_return(retval)
      @vt_bundle.stub!(meth).and_return(retval)
    end
    @vt_regular.stub!(:is_bundle?).and_return(false)
    @vt_bundle.stub!(:is_bundle?).and_return(true)
  end

  describe "regular voucher when first created", :shared => true do
    it "should not be reserved" do  @v.should_not be_reserved  end
    it "should not belong to anyone" do @v.customer.should be_nil end
    it "should not be valid" do @v.should_not be_valid end
    it "should not show up as processed by anyone" do
      @v.processed_by.should be_nil
    end
    it "should have no associated purchasemethod" do
      @v.purchasemethod.should be_nil
    end
  end

  describe "regular voucher when templated from vouchertype" do
    before(:all) do
      @v = Voucher.new_from_vouchertype(@vt_regular)
    end
    it_should_behave_like "regular voucher when first created"
    it "should have a vouchertype" do  @v.vouchertype.should_not be_nil end
    it "price should match its vouchertype" do
      @vt_regular.stub!(:price).and_return(10.00)
      @v.price.should == 10.00
    end
    it "should not be valid" do @v.should_not be_valid end
  end

  describe "expired voucher" do
    before(:all) do
      @v = Voucher.new_from_vouchertype(@vt_regular)
      @v.expiration_date = 1.month.ago
    end
    it "should not be valid today" do
      @v.should_not be_valid_today
    end
    it "should not be reservable" do
      @v.should_not be_reservable
    end
  end
  describe "reserving a valid voucher for a showdate for which it's valid" do
    context "when voucher is not reservable" do
      it "reservation should fail" do
        pending
      end
    end
    context "when voucher is reservable " do
      context "self-reservation by customer"
      context "reservation by box office agent"
    end
  end

end


