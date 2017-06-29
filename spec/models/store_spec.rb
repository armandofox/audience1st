require 'rails_helper'

describe Store, "credit card" do
  before(:each) do
    @purchaser = create(:customer) 
    @order = Order.new(:purchaser => @purchaser)
    allow(@order).to receive(:total_price).and_return(25.00)
  end
  describe 'refund' do
    
  end
  describe 'successful payment' do
    before :each do
      allow(Stripe::Charge).to receive(:create).and_return(double('result', :id => 'auth'))
    end
    it 'processes charge thru Stripe' do
      @order.purchase_args = {:credit_card_token => 'xyz'}
      expect(Stripe::Charge).
        to receive(:create).
        with(hash_including(:amount => 2500, :currency => 'usd', :card => 'xyz', :description => @purchaser.inspect) )
      Store.pay_with_credit_card(@order)
    end
    it 'records authorization ID' do
      Store.pay_with_credit_card(@order)
      @order.authorization.should == 'auth'
    end
  end
  describe 'unsuccessful purchase' do
    before :each do
      allow(Stripe::Charge).to receive(:create).and_raise(Stripe::StripeError.new('BOOM'))
    end
    it 'should return nil' do
      Store.pay_with_credit_card(@order).should be_nil
    end
    it 'should record the error' do
      Store.pay_with_credit_card(@order)
      @order.errors.full_messages.should include('Credit card payment error: BOOM')
    end
  end
end
