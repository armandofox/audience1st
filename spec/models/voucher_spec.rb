require 'spec_helper'
include BasicModels

describe Voucher do

  before :all do
    #  some Vouchertype objects for these tests
    args = {
      :fulfillment_needed => false,
      :season => Time.now.year
    }
    @vt_regular = Vouchertype.create!(args.merge({
          :name => 'regular voucher',
          :category => 'revenue',
          :account_code => AccountCode.default_account_code,
          :price => 10.00}))
    @vt_subscriber = Vouchertype.create!(args.merge({
          :name => 'subscriber voucher',
          :category => :subscriber,
          :account_code => AccountCode.default_account_code}))
    @vt_bundle = Vouchertype.create!(args.merge({
          :name => 'bundle voucher',
          :category => 'bundle',
          :price => 25.00,
          :account_code => AccountCode.default_account_code,
          :included_vouchers => {@vt_subscriber.id => 2}}))
    @vt_nonticket = Vouchertype.create!(args.merge({
          :name => 'fee',
          :category => 'nonticket',
          :price => 5.00,
          :account_code => AccountCode.default_account_code}))
  end

  describe "transferring multiple vouchers" do
    before(:each) do
      @vouchers = Array.new(2) do |i|
        @from = mock_model(Showdate)
        @to = BasicModels.create_one_showdate(Time.now.tomorrow)
        @logged_in = mock_model(Customer)
        @customer = BasicModels.create_generic_customer
        v = Voucher.new_from_vouchertype(@vt_regular)
        v.reserve(@from,@logged_in).update_attribute(:customer_id, @customer.id)
        v
      end
    end
    it "should transfer to the new showdate" do
      Voucher.transfer_multiple(@vouchers, @to, @logged_in)
      @vouchers.each { |v| @to.vouchers.should include(v) }
    end
    it "should do nothing if any of the vouchers is invalid" do
      lambda do
        Voucher.transfer_multiple(@vouchers.push(Voucher.new),@to,@logged_in)
      end.should raise_error(ActiveRecord::RecordInvalid)
      @vouchers.each { |v| @to.vouchers.should_not include(v) }
    end
  end
      
  describe "regular voucher" do
    context "when templated from vouchertype", :shared => true do
      it "should not be reserved" do  @v.should_not be_reserved  end
      it "should not belong to anyone" do @v.customer.should be_nil end
      it "should take on the vouchertype's season validity" do
        @v.season.should == @v.vouchertype.season
      end
      it "should take on the vouchertype's category" do
        @v.category.should == @v.vouchertype.category
      end
      it "should not show up as processed by anyone" do
        @v.processed_by.should be_nil
      end
      it "should have a vouchertype" do  @v.vouchertype.should == @vt_regular end
      it "price should match its vouchertype" do
        @v.price.should == 10.00
      end
    end
    context "with no options" do
      before(:each) do
        @v = Voucher.new_from_vouchertype(@vt_regular)
      end
      it_should_behave_like "when templated from vouchertype"
      it "should be valid" do
        @v.should be_valid, @v.errors.full_messages.join("\n")
      end
      it "should have a default purchasemethod if none supplied" do
        @v.purchasemethod.should_not be_nil
      end
    end
    context "with supplied purchasemethod" do
      before(:each) do
        @purchasemethod = Purchasemethod.create!
        @v = Voucher.new_from_vouchertype(@vt_regular, :purchasemethod => @purchasemethod)
      it "should use the supplied purchasemethod" do
          @v.purchase_method.should == @purchasemethod
        end
      end
    end
  end

  describe "nonticket voucher" do
    before(:each) do
      @v = Voucher.new_from_vouchertype(@vt_nonticket)
      @v.purchasemethod = mock_model(Purchasemethod)
      @v.save!
    end
  end

  describe "expired voucher" do
    before(:all) do
      @vt_regular.update_attribute(:season, Time.now.year - 2)
      @v = Voucher.new_from_vouchertype(@vt_regular, :purchasemethod => Purchasemethod.create!)
      @v.should be_valid
    end
    it "should not be valid today" do
      @v.should_not be_valid_today
    end
    it "should not be reservable" do
      @v.should_not be_reservable
    end
  end

  describe "when valid for a showdate" do
    before(:each) do
      @c = BasicModels.create_customer_by_role(:patron)
      @v = Voucher.new_from_vouchertype(@vt_regular, :purchasemethod => Purchasemethod.create!)
      @c.vouchers << @v
      @c.save!
      @sd = BasicModels.create_one_showdate(1.day.from_now)
    end
    context "that's sold out" do
      before(:each) do
      end
      describe "when reserved by box office" do
        before(:each) do
          @b = BasicModels.create_customer_by_role(:boxoffice)
        end
        before(:each) do
          ValidVoucher.should_receive(:numseats_for_showdate_by_vouchertype).with(
            @sd.id,
            @c,
            @vt_regular,
            {:redeeming => true, :ignore_cutoff => true}).and_return(mock('AvailableSeat', :available? => nil))
          av = @v.reserve_for(@sd.id, @c.id, '', :ignore_cutoff => @b.is_boxoffice)
        end
        it "should succeed" do
          @v.should be_reserved
        end
        it "should be tied to that showdate" do
          @v.showdate.id.should == @sd.id
        end
      end
      describe "when reserved by customer" do
        before(:each) do
        end
        it "should not succeed" do
          ValidVoucher.should_receive(:numseats_for_showdate_by_vouchertype).
            with(@sd.id, @c, @vt_regular, {:redeeming => true, :ignore_cutoff => false}).
            and_return(mock('AvailableSeat', :available? => nil, :explanation => ''))
          @v.reserve_for(@sd.id, @c.id, '', :ignore_cutoff => @c.is_boxoffice)
          @v.should_not be_reserved
        end
        it "should display an explanation" do
          as = mock('AvailableSeat', :available? => nil)
          as.should_receive(:explanation).and_return('')
          ValidVoucher.should_receive(:numseats_for_showdate_by_vouchertype).
            with(@sd.id, @c, @vt_regular, {:redeeming => true, :ignore_cutoff => false}).
            and_return(as)
          @v.reserve_for(@sd.id,@c.id, '', :ignore_cutoff => @c.is_boxoffice)
        end
      end
    end
  end
  describe "transferring" do
    before(:each) do
      @from = BasicModels.create_generic_customer
      @v = Voucher.new_from_vouchertype(@vt_regular, :purchasemethod => Purchasemethod.create!)
      @v.should be_valid
      @from.vouchers << @v
      @from.save!
    end
    context "when recipient exists" do
      before(:each) do
        @to = BasicModels.create_generic_customer
      end
      it "should add the voucher to the recipient's account" do
        @v.transfer_to_customer(@to)
        @to.vouchers.should include(@v)
      end
      it "should remove the voucher from the transferor's account" do
        @v.transfer_to_customer(@to)
        @from.vouchers.should_not include(@v)
      end
    end
    context "when recipient doesn't exist" do
      before(:all) do
        @to = Customer.new(:first_name => "Jane", :last_name => "Nonexistent")
      end
      it "should not cause an error" do
        lambda { @v.transfer_to_customer(@to) }.should_not raise_error
      end
      it "should not remove the voucher from the transferor's account" do
        @v.transfer_to_customer(@to)
        @from.vouchers.should include(@v)
      end
    end
  end
  describe "bundles" do
    context "when created" do
      it "should record bundle ID in each bundle voucher"
    end
    context "when destroyed" do
      it "should destroy associated bundled vouchers"
    end
  end
end


