require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Utils

describe Vouchertype do

  describe "validations" do
    before(:each) do
      @vt = Vouchertype.new(:price => 1.0,
                            :offer_public => Vouchertype::ANYONE,
                            :name => "Example",
                            :subscription => false,
                            :walkup_sale_allowed => true,
                            :comments => "A comment",
                            :account_code => "9999",
                            :valid_date => Time.now.yesterday,
                            :expiration_date => Time.now.tomorrow
                            )
    end
    describe "vouchers in general" do
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
        @vt.subscription = true
        @vt.walkup_sale_allowed = true
        @vt.should_not be_valid
      end
    end
    describe "subscription vouchers" do
      before(:each) do
        @vt.subscription = true
        @vt.walkup_sale_allowed = false
      end
      it "should not be valid for more than (2 years - 1 day)" do
        stub_month_and_day(5, 3)
        @vt.valid_date = @vt.expiration_date - 2.years
        @vt.should_not be_valid
        @vt.errors[:base].should match(/May +2/)
      end
    end
     
    describe "a subscription voucher valid for 2008" do
      before(:each) do
        @start = Time.parse("Feb 5, 2008")
        stub_month_and_day(@start.month, @start.day)
      end
      it "should have an end date no later than end of 2008 season" do
        @vt.valid_date = @start - 3.months
        @vt.expiration_date = @start.at_end_of_season(2008)
        puts @vt.inspect
        puts Time.now.at_beginning_of_season(2008).inspect
        puts Time.now.at_end_of_season(2008).inspect
        @vt.should be_valid_for_season(2008)
      end
      it "should not have a start date more than 1 year before season start" do
        @vt.expiration_date = @start + 1.year
        @vt.valid_date = @start - 1.month - 1.day
        @vt.should_not be_valid_for_season(2008)
      end
      it "should not appear to be a 2007 subscription, even though its validity date is in 2007" do
        @vt.expiration_date = @start + 1.year
        @vt.valid_date = @start - 10.months
        @vt.should_not be_valid_for_season(2007)
      end
    end
  end

end
