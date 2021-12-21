require 'rails_helper'

describe Store, "landing page" do
  before(:each) do
    @sd1 = create(:showdate, :thedate => 4.weeks.from_now)
    @sd2 = create(:showdate, :thedate => 1.week.from_now)
  end
  context 'for patron' do
    before(:each) do ; @u = create(:customer) ; end
    it 'orders shows by first showdate, not by listing date' do
      @sd1.show.update_attributes!(:listing_date => 3.weeks.ago) # earlier listing date, later showdate
      @sd2.show.update_attributes!(:listing_date => 1.day.ago)
      @s = Store::Flow.new(@u, @u, nil, {})
      @s.setup
      expect(@s.all_shows).to eq([@sd2.show, @sd1.show])
    end
    describe "with valid & listed showdate" do
      before(:each) do
        @s = Store::Flow.new(@u, @u, nil, {:showdate_id => @sd1.id})
        @s.setup
      end
      it 'selects showdate' do ; expect(@s.sd.id).to eq(@sd1.id) ; end
      it 'includes shows' do ; expect(@s.all_shows).to eq ([@sd2.show,@sd1.show]) ; end
    end
    describe 'with invalid showdate' do
      it 'defaults to earliest valid showdate with tickets' do
        @s = Store::Flow.new(@u, @u, nil, {:showdate_id => 99999})
        @s.setup
        expect(@s.sd.id).to eq (@sd2.id)
      end
    end
    describe 'with valid but not-yet-listed show' do
      before(:each) do
        @sd1.show.update_attributes!(:listing_date => 1.week.from_now)
        @s = Store::Flow.new(@u, @u, nil, {:showdate_id => @sd1.id })
        @s.setup
      end
      it 'does not list show' do ; expect(@s.all_shows).not_to include(@sd1.show) ; end
      it 'does not select showdate' do ; expect(@s.sd).not_to eq(@sd1) ; end
    end
  end
  context 'for admin' do
    before(:each) do ; @u = create(:boxoffice) ; end
    it 'lists not-yet-listed show' do
      @sd1.show.update_attributes!(:listing_date => 1.week.from_now)
      @s = Store::Flow.new(@u, @u, true, {:showdate_id => @sd1.id })
      @s.setup
      expect(@s.all_shows).to include(@sd1.show)
    end
    it 'lists shows in the past' do
      @s3 = create(:show, :season => (Time.this_season - 1))
      @sd3 = create(:showdate, :show => @s3, :thedate => 3.weeks.ago)
      @s = Store::Flow.new(@u, @u, true, {:showdate_id => @sd3.id})
      @s.setup
      expect(@s.all_shows).to include(@s3)
      expect(@s.sd.id).to eq(@sd3.id)
    end
  end
end

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
      Store::Payment.pay_with_credit_card(@order)
    end
    it 'records authorization ID' do
      Store::Payment.pay_with_credit_card(@order)
      expect(@order.authorization).to eq('auth')
    end
  end
  describe 'unsuccessful purchase' do
    before :each do
      allow(Stripe::Charge).to receive(:create).and_raise(Stripe::StripeError.new('BOOM'))
    end
    it 'should return nil' do
      expect(Store::Payment.pay_with_credit_card(@order)).to be_nil
    end
    it 'should record the error' do
      Store::Payment.pay_with_credit_card(@order)
      expect(@order.errors.full_messages).to include('Credit card payment error: BOOM')
    end
  end
end

