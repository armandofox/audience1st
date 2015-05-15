require 'spec_helper'

describe Order, 'adding' do
  before :each do 
    @vv = ValidVoucher.create!(
      :vouchertype => create(:revenue_vouchertype, :price => 7),
      :showdate => create(:showdate, :date => 1.day.from_now),
      :start_sales => Time.now,
      :end_sales => 10.minutes.from_now,
      :max_sales_for_type => 100)
  end
  before :each do
    @order = Order.new 
  end
  describe 'tickets' do
    before :each do  ;    @order.add_tickets(@vv, 3) ;   end
    it 'should work when cart is empty' do ; @order.ticket_count.should == 3  ; end
    it 'should add to existing tickets' do
      expect { @order.add_tickets(@vv, 2) }.to change { @order.ticket_count }.by(2)
    end
    it 'should empty cart' do
      expect { @order.empty_cart! }.to change { @order.ticket_count}.to(0)
    end
    it 'should serialize cart' do
      @order.save!
      reloaded = Order.find(@order.id)
      reloaded.ticket_count.should == 3
    end
  end
  describe 'donations' do
    before :each do ; @donation = build(:donation, :amount => 17) ; end
    it 'should add donation' do
      @order.add_donation(@donation)
      @order.donation.should be_a_kind_of(Donation)
    end
    it 'should serialize donation' do
      @order.donation = @donation
      @order.save!
      reloaded = Order.find(@order.id)
      reloaded.donation.amount.should == @donation.amount
      reloaded.donation.account_code_id.should == @donation.account_code_id
    end
  end
  describe 'and getting total price' do
    it 'without donation' do
      vv2 = ValidVoucher.create!(
        :vouchertype => create(:revenue_vouchertype, :price => 3),
        :showdate => create(:showdate, :date => 1.day.from_now),
        :start_sales => Time.now,
        :end_sales => 10.minutes.from_now,
        :max_sales_for_type => 100)
      expect { @order.add_tickets(@vv, 2) ; @order.add_tickets(vv2, 3) }.to change { @order.total_price }.to(23.0)
    end
    describe 'with donation' do
      before :each do ; @donation = build(:donation, :amount => 17) ; end
      specify 'and tickets' do
        @order.add_tickets(@vv, 2)
        @order.add_donation(@donation)   # at $17
        @order.total_price.should == 31.0
      end
      specify 'with donation only' do
        @order.add_donation(@donation)
        @order.add_donation(@donation)   # should be idempotent
        @order.total_price.should == 17.0
      end
    end
  end
end
