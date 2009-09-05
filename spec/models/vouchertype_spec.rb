require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Vouchertype do

  describe "validations" do

    before(:each) do
      @vt = Vouchertype.new(:price => 1.0,
                            :offer_public => Vouchertype::ANYONE,
                            :name => "Example",
                            :is_subscription => false,
                            :walkup_sale_allowed => true,
                            :comments => "A comment",
                            :account_code => "9999",
                            :valid_date => Time.now.yesterday,
                            :expiration_date => Time.now.tomorrow
                            )
    end
    it "should be valid with valid attributes" do
      @vt.should be_valid
    end
    it "should not be zero-price if accessible to anyone" do
      @vt.price = 0.0
      @vt.offer_public = Vouchertype::ANYONE
      @vt.should_not be_valid
    end
    it "should not be zero-price if accessible for subscriber purchase" do
      @vt.price = 0.0
      @vt.offer_public = Vouchertype::SUBSCRIBERS
      @vt.should_not be_valid
    end
    it "may be zero-price if accessible to boxoffice only" do
      @vt.price = 0.0
      @vt.offer_public = Vouchertype::BOXOFFICE
      @vt.should be_valid
    end
    it "may be zero-price if provided by external reseller" do
      @vt.price = 0.0
      @vt.offer_public = Vouchertype::EXTERNAL
      @vt.should be_valid
    end
    it "should be valid for redemption now" do
      @vt.should be_valid_now
    end
    it "should not have a bogus offer-to-whom field" do
      @vt.offer_public = 999
      @vt.should_not be_valid
    end
    it "should not have a negative price" do
      @vt = Vouchertype.new(:price => -1.0)
      @vt.should_not be_valid
    end
    it "should not be sold as walkup if it's a subscription" do
      @vt.is_subscription = true
      @vt.walkup_sale_allowed = true
      @vt.should_not be_valid
    end
  end

end
