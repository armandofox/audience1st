require 'spec_helper'
include BasicModels

describe Voucher do

  before :each do
    #  some Vouchertype objects for these tests
    args = {
      :fulfillment_needed => false,
      :season => Time.now.year
    }
    @vt_regular = BasicModels.create_revenue_vouchertype
    @vt_subscriber = BasicModels.create_included_vouchertype
    @vt_bundle = BasicModels.create_bundle_vouchertype(:included_vouchers => {@vt_subscriber.id => 2})
    @basic_showdate = BasicModels.create_one_showdate(Time.now.tomorrow)
  end

  describe "multiple voucher" do
    before(:each) do
      @vouchers = Array.new(2) do |i|
        @from = mock_model(Showdate)
        @to = BasicModels.create_one_showdate(Time.now.tomorrow)
        @logged_in = mock_model(Customer)
        @customer = BasicModels.create_generic_customer
        @invalid_voucher = Voucher.new
        @invalid_voucher.stub!(:valid?).and_return(nil)
        v = Voucher.new_from_vouchertype(@vt_regular)
        v.reserve(@from,@logged_in).update_attribute(:customer_id, @customer.id)
        v
      end
    end
    describe "transferring" do
      it "should transfer to the new showdate" do
        Voucher.transfer_multiple(@vouchers, @to, @logged_in)
        @vouchers.each { |v| @to.vouchers.should include(v) }
      end
      it "should do nothing if any of the vouchers is invalid" do
        lambda do
          Voucher.transfer_multiple(@vouchers.push(@invalid_voucher),@to,@logged_in)
        end.should raise_error(ActiveRecord::RecordInvalid)
        @vouchers.each { |v| @to.vouchers.should_not include(v) }
      end
    end
    describe "deletion" do
      it "should destroy the vouchers" do
        ids = @vouchers.map(&:id)
        Voucher.destroy_multiple(@vouchers, @logged_in)
        ids.each { |id| Voucher.find_by_id(id).should be_nil }
      end
    end
  end

  describe "templated from vouchertype" do
    subject { Voucher.new_from_vouchertype(@vt_regular) }
    it { should be_valid }
    it { should_not be_reserved }
    its(:customer) { should be_nil }
    its(:category) { should == @vt_regular.category }
    its(:processed_by) { should be_nil }
    its(:vouchertype) { should == @vt_regular }
    its(:amount) { should == 10.00 }
  end

  describe "expired voucher" do
    before(:each) do
      @vt_regular.update_attribute(:season, Time.now.year - 2)
      @v = Voucher.new_from_vouchertype(@vt_regular)
      @v.should be_valid
    end
    it "should not be valid today" do
      @v.should_not be_valid_today
    end
    it "should not be reservable" do
      @v.should_not be_reservable
    end
  end

  describe "customer reserving a sold-out showdate" do
    before(:each) do
      @c = BasicModels.create_customer_by_role(:patron)
      @v = Voucher.new_from_vouchertype(@vt_regular)
      @c.vouchers << @v
      @sd = BasicModels.create_one_showdate(1.day.from_now)
      @v.stub(:valid_voucher_adjusted_for).and_return(mock_model(ValidVoucher, :max_sales_for_type => 0, :explanation => 'Event is sold out'))
      @success = @v.reserve_for(@sd, Customer.generic_customer, 'foo')
    end
    it 'should not succeed' do
      @v.should_not be_reserved
      @success.should_not be_true
    end
    it 'should explain that show is sold out' do
      @v.errors.full_messages.should include('Event is sold out')
    end
  end
  describe "transferring" do
    before(:each) do
      @from = BasicModels.create_generic_customer
      @v = Voucher.new_from_vouchertype(@vt_regular)
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
end


