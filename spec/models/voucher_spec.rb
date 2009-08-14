require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Voucher do

  before :all do
    # mock some Vouchertype objects for these tests
    @vt_regular = mock_model(RevenueVouchertype)
    @vt_bundle = mock_model(BundleVouchertype)
    { :fulfillment_needed => false,
      :valid_date => Time.now - 1.month,
      :expiration_date => Time.now + 1.month }.each_pair do |meth,retval|
      @vt_regular.stub!(meth).and_return(retval)
      @vt_bundle.stub!(meth).and_return(retval)
    end
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

  context "regular voucher when templated from vouchertype" do
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

end
