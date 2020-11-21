require 'rails_helper'

describe RefundedItem do
  before(:each) do ; @by = mock_model(Customer, :full_name => 'A B') ; end
  describe 'revenue voucher cancellation' do
    before(:each) do
      @purchase_date = 2.days.ago
      Timecop.travel @purchase_date do
        @voucher = create(:revenue_voucher, :amount => 15.50)
        @voucher.save!
      end
      @refund = RefundedItem.from_cancellation(@voucher)
    end
    it 'is valid' do ; expect(@refund).to be_valid ; end
    it 'has correct price' do
      expect(@refund.amount).to eq(-15.50)
    end
    describe 'after cancellation' do
      before(:each) do
        @voucher = @voucher.cancel!(@by)
        @refund = @voucher.refunded_item
      end
      it 'is linked to original item' do
        expect(@refund.canceled_item).to eq(@voucher)
      end
      it 'canceled item has correct price' do
        expect(@voucher.amount).to eq(15.50)
      end
      it 'canceled item updated_at matches original purchase date' do
        expect(@voucher.updated_at).to be_within(1.second).of @purchase_date
      end
      specify 'refund item updated_at matches refund date' do
        expect(@refund.updated_at).to be_within(1.second).of Time.current
      end
    end
  end
  specify 'zero-revenue voucher cancellation does not generate a refund item' do
    @voucher = create(:comp_voucher)
    expect(RefundedItem).not_to receive(:from_cancellation)
    @voucher.cancel!(@by)
  end
  describe 'subscription voucher cancellation' do
    before(:each) do
      @purchase_date = 2.days.ago
      Timecop.travel @purchase_date do
        @sub = create(:bundle_voucher, :including => {
            create(:subscriber_voucher) => 2,
            create(:subscriber_voucher) => 1
          })
      end
    end
    it 'generates exactly one refund item' do
      expect(RefundedItem).to receive(:from_cancellation).exactly(1).times
      @sub.cancel!(@by)
    end
    it 'links refund item to actual sub purchase' do
      @sub = @sub.cancel!(@by)
      refund = RefundedItem.where(:bundle_id => @sub.id).first
      expect(refund.canceled_item).to eq(@sub)
    end
    it "leaves canceled item's updated_on as original purchase date" do
      @sub = @sub.cancel!(@by)
      expect(@sub.updated_at).to be_within(1.second).of @purchase_date
    end
  end
end

    
