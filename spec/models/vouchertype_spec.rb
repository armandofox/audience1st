require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Utils

describe Vouchertype do

  describe "nonticket vouchertypes" do
    it "should be valid" do
      @vtn = Vouchertype.new(
        :price => 5.0,
        :category => :nonticket,
        :offer_public => Vouchertype::BOXOFFICE,
        :name => "Fee",
        :subscription => false,
        :walkup_sale_allowed => true,
        :comments => "A comment",
        :account_code => "9997",
        :valid_date => Time.now.yesterday,
        :expiration_date => Time.now.tomorrow
        )
      @vtn.should be_valid
    end
  end
  describe "validations" do
    before(:each) do
      @vt = Vouchertype.new(:price => 1.0,
        :offer_public => Vouchertype::ANYONE,
        :category => :revenue,
        :name => "Example",
        :subscription => false,
        :walkup_sale_allowed => true,
        :comments => "A comment",
        :account_code => "9999",
        :valid_date => Time.now.yesterday,
        :expiration_date => Time.now.tomorrow
        )
    end
    describe "vouchertypes in general" do
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
    describe "bundles" do
      before :each do
        args = {
          :offer_public => Vouchertype::BOXOFFICE,
          :subscription => false,
          :walkup_sale_allowed => true,
          :comments => "A comment",
          :account_code => "9999",
          :valid_date => Time.now.yesterday,
          :expiration_date => Time.now.tomorrow
        }
        @vtb = Vouchertype.new(args.merge({
              :category => :bundle,
              :name => "Bundle"}))
        @vt_free = Vouchertype.create!(args.merge({
              :category => :comp,
              :price => 0,
              :name => "Free"}))
        @vt_notfree = Vouchertype.create!(args.merge({
              :category => :revenue,
              :price => 1,
              :name => "Revenue"}))
      end
      it "should be invalid if contains any nonzero-price vouchers" do
        @vtb.included_vouchers = {@vt_free.id => 1, @vt_notfree.id => 1}
        @vtb.should_not be_valid
        @vtb.errors.full_messages.should include("Bundle can't include revenue voucher #{@vt_notfree.id} (#{@vt_notfree.name})"), @vtb.errors.full_messages.join(',')
      end
      it "should  be valid with only zero-price vouchers" do
        @vtb.included_vouchers = {@vt_free.id => 1, @vt_notfree.id => 0}
      end
    end
    describe "subscription" do
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
     
    describe "a subscription vouchertype valid for 2008" do
      before(:each) do
        @start = Time.parse("Feb 5, 2008")
        stub_month_and_day(@start.month, @start.day)
      end
      it "should have an end date no later than end of 2008 season" do
        @vt.valid_date = @start - 3.months
        @vt.expiration_date = @start.at_end_of_season(2008)
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

  describe "selecting" do
    describe "subscriptions" do
      before(:each) do
        generic_args =  {
          :price => 5.0,
        :walkup_sale_allowed => false,
        :comments => "A comment",
        :account_code => "9997",
        :valid_date => 1.day.ago,
        :expiration_date => 1.day.from_now
        }
        @sub_anyone = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :subscription => true, :name => "Sub for anyone",
              :offer_public => Vouchertype::ANYONE }))
        @sub_boxoffice = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :offer_public => Vouchertype::BOXOFFICE,
              :subscription => true,:name => "Sub for boxoffice" }))
        @sub_subscriber = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :offer_public => Vouchertype::SUBSCRIBERS,
              :subscription => true, :name => "Sub for subscribers"  }))
        @sub_external = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :offer_public => Vouchertype::EXTERNAL,
              :subscription => true, :name => "Sub for external sale" }))
        @sub_expired = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :offer_public => Vouchertype::ANYONE,
              :subscription => true, :name => "Expired sub",
              :valid_date => 1.year.ago, :expiration_date => 1.month.ago     }))
        @nonsub_bundle = Vouchertype.create!(generic_args.merge({
              :category => :bundle, :offer_public => Vouchertype::ANYONE,
              :subscription => false, :name => "Nonsub"   }))
      end
      describe "in general", :shared => true do
        it "should include generic sub" do
          @subs.should include(@sub_anyone)
        end
        it "should exclude nonsubscriptions" do
          @subs.should_not include(@nonsub_bundle)
        end
        it "should exclude external-channel subs" do
          @subs.should_not include(@sub_external)
        end
      end
      describe "for anyone" do
        before(:each) do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => false, :next_season_subscriber? => false), admin = nil)
        end
        it_should_behave_like "in general"
        it "should exclude subscriber-only products" do
          @subs.should_not include(@sub_subscriber)
        end
        it "should exclude expired products" do
          @subs.should_not include(@sub_expired)
        end
        it "should exclude boxoffice-only products" do
          @subs.should_not include(@sub_boxoffice)
        end
      end
      describe "for boxoffice", :shared => true do
        before(:each) do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => false, :next_season_subscriber? => false), admin = true)
        end
        it_should_behave_like "in general"
        it "should include boxoffice-only products" do
          @subs.should include(@sub_boxoffice)
        end
        it "should include expired products" do
          @subs.should include(@sub_expired)
        end
      end
      describe "subscriber" do
        before do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => true, :next_season_subscriber? => false), admin = true)
        end
        it_should_behave_like "for boxoffice"
      end
      describe "nonsubscriber" do
        before do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => false, :next_season_subscriber? => false), admin = true)
        end
        it_should_behave_like "for boxoffice"
      end
      describe "for non-boxoffice subscriber", :shared => true do
        it "should include subscriber-only products" do
          @subs.should include(@sub_subscriber)
        end
        it "should exclude expired products" do
          @subs.should_not include(@sub_expired)
        end
      end
      describe "this season" do
        before do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => true, :next_season_subscriber? => false), admin = false)
        end
        it_should_behave_like "for non-boxoffice subscriber"
      end
      describe "next season" do
        before do
          @subs = Vouchertype.subscriptions_available_to(mock_model(Customer, :subscriber? => false, :next_season_subscriber? => true), admin = false)
        end
        it_should_behave_like "for non-boxoffice subscriber"
      end
    end
  end
end
