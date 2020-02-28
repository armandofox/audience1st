require 'rails_helper'

describe Voucher do
  
  before :each do
    #  some Vouchertype objects for these tests
    args = {
      :fulfillment_needed => false,
      :season => Time.current.year
    }
    @vt_regular = create(:revenue_vouchertype, :price => 10)
    @vt_subscriber = create(:vouchertype_included_in_bundle)
    @vt_bundle = create(:bundle, :including  => {@vt_subscriber => 2})
    @basic_showdate = create(:showdate, :date => Time.current.tomorrow)
  end

  describe 'redeemability' do
    before(:each) do
      @showdates = Array.new(3) { create(:showdate) }
      create(:valid_voucher, :vouchertype => @vt_regular, :showdate => @showdates[0])
      create(:valid_voucher, :vouchertype => @vt_regular, :showdate => @showdates[2])
      @v1 = create(:revenue_voucher, :vouchertype => @vt_regular)
      @v2 = create(:revenue_voucher)
      expect(Voucher.count).to eq(2)
    end
    it 'for some showdates' do
      v = Voucher.valid_for_showdate(@showdates[0])
      expect(v).to include(@v1)
      expect(v).not_to include(@v2)
    end
    it 'and other shows' do
      v = Voucher.valid_for_showdate(@showdates[0])
      expect(v).to include(@v1)
      expect(v).not_to include(@v2)
    end      
    it 'for no showdates' do
      expect(Voucher.valid_for_showdate(@showdates[1])).to be_empty
    end
  end

  describe "multiple voucher" do
    before(:each) do
      @vouchers = Array.new(2) do |i|
        @from = mock_model(Showdate)
        @to = create(:showdate, :date => Time.current.tomorrow)
        @logged_in = mock_model(Customer)
        @customer = create(:customer)
        @invalid_voucher = Voucher.new
        allow(@invalid_voucher).to receive(:valid?).and_return(nil)
        v = VoucherInstantiator.new(create(:revenue_vouchertype)).from_vouchertype.first
        v.reserve(@from,@logged_in).update_attribute(:customer_id, @customer.id)
        v
      end
    end
    describe "transferring" do
      it "should transfer to the new showdate" do
        Voucher.change_showdate_multiple(@vouchers, @to, @logged_in)
        @vouchers.each { |v| expect(@to.vouchers).to include(v) }
      end
      it "should do nothing if any of the vouchers is invalid" do
        expect do
          Voucher.change_showdate_multiple(@vouchers.push(@invalid_voucher),@to,@logged_in)
        end.to raise_error(ActiveRecord::RecordInvalid)
        @vouchers.each { |v| expect(@to.vouchers).not_to include(v) }
      end
    end
  end

  describe "templated from vouchertype" do
    subject { VoucherInstantiator.new(@vt=create(:revenue_vouchertype)).from_vouchertype.first }
    it { is_expected.to be_valid }
    it { is_expected.not_to be_reserved }
    its(:customer) { should be_nil }
    its(:category) { should == 'revenue' }
    its(:processed_by) { should be_nil }
    its(:vouchertype) { should == @vt }
    its(:amount) { should == 12.00 }
  end

  describe "expired voucher" do
    before(:each) do
      @vt_regular.update_attribute(:season, Time.current.year - 2)
      @v = VoucherInstantiator.new(@vt_regular).from_vouchertype.first
      expect(@v).to be_valid
    end
    it "should not be valid today" do
      expect(@v).not_to be_valid_today
    end
    it "should not be reservable" do
      expect(@v).not_to be_reservable
    end
  end

  describe "customer reserving a sold-out showdate" do
    before(:each) do
      @c = create(:customer)
      @v = VoucherInstantiator.new(@vt_regular).from_vouchertype.first
      @c.vouchers << @v
      @sd = create(:showdate, :date => 1.day.from_now)
      allow(@v).to receive(:valid_voucher_adjusted_for).and_return(mock_model(ValidVoucher, :max_sales_for_this_patron => 0, :explanation => 'Event is sold out'))
      expect { @success = @v.reserve_for(@sd, Customer.walkup_customer, 'foo') }.to raise_error(Voucher::ReservationError)
    end
    it 'should not succeed' do
      expect(@v).not_to be_reserved
    end
    it 'should explain that show is sold out' do
      expect(@v.errors.full_messages).to include('Event is sold out')
    end
  end
  describe "transferring" do
    before(:each) do
      @from = create(:customer)
      @v = create(:revenue_voucher, :customer => @from)
    end
    context "when recipient exists" do
      before(:each) do
        @to = create(:customer)
      end
      it "should add the voucher to the recipient's account" do
        expect(@from.vouchers).to include(@v)
        @v.transfer_to_customer(@to)
        expect(@to.vouchers).to include(@v)
      end
      it "should remove the voucher from the transferor's account" do
        @v.transfer_to_customer(@to)
        @from.reload
        expect(@from.vouchers).not_to include(@v)
      end
    end
    context 'for bundles' do
      before(:each) do
        @from = create(:customer)
        @to = create(:customer)
        @bundle = create(:bundle, :including =>
          { (@vt1 = create(:vouchertype_included_in_bundle)) => 2,
            (@vt2 = create(:vouchertype_included_in_bundle)) => 1 })
        vouchers = VoucherInstantiator.new(@bundle).from_vouchertype
        vouchers.each(&:finalize!)
        @from.vouchers += vouchers
        @from.save!
        # now transfer it
        @from.vouchers.find_by(:vouchertype_id => @bundle.id).transfer_to_customer(@to)
      end
      it 'transfers the bundle voucher' do
        expect(@to.vouchers).to have_voucher_matching(:vouchertype_id => @bundle.id)
      end
      it 'transfers the included vouchers' do
        expect(@to.vouchers).to have_vouchers_matching(2, :vouchertype_id => @vt1.id)
        expect(@to.vouchers).to have_vouchers_matching(1, :vouchertype_id => @vt2.id)
      end
    end
  end
end


