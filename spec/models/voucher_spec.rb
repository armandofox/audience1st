require 'rails_helper'

describe Voucher do

  before :each do
    #  some Vouchertype objects for these tests
    args = {
      :fulfillment_needed => false,
      :season => Time.now.year
    }
    @vt_regular = create(:revenue_vouchertype, :price => 10)
    @vt_subscriber = create(:vouchertype_included_in_bundle)
    @vt_bundle = create(:bundle, :including  => {@vt_subscriber => 2})
    @basic_showdate = create(:showdate, :date => Time.now.tomorrow)
  end

  describe "multiple voucher" do
    before(:each) do
      @vouchers = Array.new(2) do |i|
        @from = mock_model(Showdate)
        @to = create(:showdate, :date => Time.now.tomorrow)
        @logged_in = mock_model(Customer)
        @customer = create(:customer)
        @invalid_voucher = Voucher.new
        allow(@invalid_voucher).to_receive(:valid?).and_return(nil)
        v = Voucher.new_from_vouchertype(@vt_regular)
        v.reserve(@from,@logged_in).update_attribute(:customer_id, @customer.id)
        v
      end
    end
    describe "transferring" do
      it "should transfer to the new showdate" do
        Voucher.change_showdate_multiple(@vouchers, @to, @logged_in)
        @vouchers.each { |v| @to.vouchers.should include(v) }
      end
      it "should do nothing if any of the vouchers is invalid" do
        lambda do
          Voucher.change_showdate_multiple(@vouchers.push(@invalid_voucher),@to,@logged_in)
        end.should raise_error(ActiveRecord::RecordInvalid)
        @vouchers.each { |v| @to.vouchers.should_not include(v) }
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
      @c = create(:customer)
      @v = Voucher.new_from_vouchertype(@vt_regular)
      @c.vouchers << @v
      @sd = create(:showdate, :date => 1.day.from_now)
      allow(@v).to_receive(:valid_voucher_adjusted_for).and_return(mock_model(ValidVoucher, :max_sales_for_this_patron => 0, :explanation => 'Event is sold out'))
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
      @from = create(:customer)
      @v = Voucher.new_from_vouchertype(@vt_regular)
      @v.should be_valid
      @from.vouchers << @v
      @from.save!
    end
    context "when recipient exists" do
      before(:each) do
        @to = create(:customer)
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
    context 'for bundles' do
      before(:each) do
        @from = create(:customer)
        @to = create(:customer)
        @bundle = create(:bundle, :including =>
          { (@vt1 = create(:vouchertype_included_in_bundle)) => 2,
            (@vt2 = create(:vouchertype_included_in_bundle)) => 1 })
        @from.vouchers << @bundle.instantiate(1)
        # now transfer it
        @from.vouchers.find_by_vouchertype_id(@bundle.id).transfer_to_customer(@to)
      end
      it 'transfers the bundle voucher' do
        @to.vouchers.should have_voucher_matching(:vouchertype_id => @bundle.id)
      end
      it 'transfers the included vouchers' do
        @to.vouchers.should have_vouchers_matching(2, :vouchertype_id => @vt1.id)
        @to.vouchers.should have_vouchers_matching(1, :vouchertype_id => @vt2.id)
      end
    end
  end
end


