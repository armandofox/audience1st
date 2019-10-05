require 'rails_helper'

describe 'finalizing' do
  # Simplify matching Customer vouchers for a particular showdate and vouchertype
  class Customer < ActiveRecord::Base
    def vouchers_for(showdate, vouchertype)
      self.vouchers.where('showdate_id = ? and vouchertype_id = ?', showdate.id, vouchertype.id)
    end
  end

  before :each do                # set these up so they're not rolled back by transaction around each example, since we test transactions in credit-card-failure case
    @vt = create(:revenue_vouchertype, :price => 7)
    @sd = create(:showdate, :date => 1.day.from_now)
    @vv = create(:valid_voucher, :vouchertype => @vt, :showdate => @sd)
    @vt2 = create(:revenue_vouchertype, :price => 3)
    @sd2 = create(:showdate, :date => 1.week.from_now)
    @vv2 = create(:valid_voucher, :vouchertype => @vt2, :showdate => @sd2)
    @donation = build(:donation, :amount => 17)
  end

  after :each do
    [@vt, @sd, @vv, @vt2, @sd2, @vv2, @donation].each { |m| m.destroy rescue nil }
  end


  context 'successful' do
    before :each do
      @order = create(:order, :comments => 'Comment')
      @order.add_tickets_without_capacity_checks(@vv,2)
      @order.add_tickets_without_capacity_checks(@vv2,1)
      @order.add_donation(@donation)
      expect(Store).not_to receive(:pay_with_credit_card) # stub this out, it has its own tests
      expect(@order.errors).to be_empty
    end
    describe 'web order' do
      shared_examples_for 'when valid' do
        it 'should be saved' do ; expect(@order).not_to be_a_new_record ; end
        it 'should include the items' do ; expect(@order.item_count).to eq(4) ; end
        it 'should have a sold-on time' do ;expect(@order.sold_on).to be_between(Time.current - 5.seconds, Time.current) ; end
        it 'should set order ID on its items' do ; @order.items.each { |i| expect(i.order_id).to eq(@order.id) } ; end
        it 'should set comments on vouchers but not donations or retail' do
          @order.items.each do |i|
            if i.kind_of?(Voucher)
              expect(i.comments).to eq('Comment')
            else
              expect(i.comments).to be_blank
            end
          end
        end
        it 'should add vouchers to customer account' do
          expect(@order.customer).to have(2).vouchers_for(@sd,@vt)
          expect(@order.customer).to have(1).vouchers_for(@sd2,@vt2)
        end
        it 'should compute total price successfully' do ; expect(@order.reload.total_price).to eq(34) ; end
      end
      it 'should add donations to customer account if purchaser==recipient' do
        @order.finalize!
        expect(@order.purchaser.donations).to include(@donation)
      end
      context 'when purchaser!=recipient' do
        before :each do
          @order.purchaser = create(:customer)
          @order.finalize!
        end
        it_should_behave_like 'when valid'
        it 'adds donations to purchaser account' do
          expect(@order.purchaser.donations).to include(@donation)
        end
        it 'does NOT add donations to recipient account' do
          expect(@order.customer.donations).not_to include(@donation)
        end
        it 'does NOT add vouchers to purchaser account' do
          expect(@order.purchaser.vouchers.size).to be_zero
        end
      end
    end
    describe 'walkup order'  do
      before :each do
        @order.purchaser = @order.customer = Customer.walkup_customer
        @order.walkup = true
        @order.finalize!
      end
      it 'should assign all vouchers to walkup customer' do
        expect(Customer.walkup_customer).to have(3).vouchers
      end
      it 'should mark all vouchers as walkup' do
        expect(Customer.walkup_customer.vouchers.all? { |v| v.walkup? }).to be_truthy
      end
    end
  end

  describe 'web order with FAILED credit card payment' do
    before :each do
      @order = create(:order,:purchasemethod => Purchasemethod.get_type_by_name('web_cc'))
      allow(@order).to receive(:ready_for_purchase?).and_return(true)
      @order.add_tickets_without_capacity_checks(@vv,2)
      @order.add_tickets_without_capacity_checks(@vv2,1)
      @order.add_donation(@donation)
      @previous_vouchers_count = Voucher.count
      @previous_donations_count = Donation.count
      allow(Store).to receive(:pay_with_credit_card).and_return(nil)
      expect { @order.finalize! }.to raise_error(Order::PaymentFailedError)
    end
    it 'should leave authorization field blank' do
      expect(@order.authorization).to be_blank
    end
    it 'should not save the items' do
      expect(Voucher.count).to eq(@previous_vouchers_count)
      expect(Donation.count).to eq(@previous_donations_count)
    end
    it 'should not add vouchers to customer' do
      expect(@order.customer.reload.vouchers).to be_empty
    end
    it 'should not complete the order' do
      expect(@order.reload).not_to be_completed
    end
  end
end
