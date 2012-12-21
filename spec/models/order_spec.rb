require 'spec_helper'
describe Order do

  def add_a_voucher_to(order)
    @vt ||= BasicModels.create_revenue_vouchertype
    @sd ||= BasicModels.create_one_showdate(Time.now.tomorrow)
    v = Voucher.anonymous_voucher_for(@sd,@vt)
    order.add_item(v)
    v
  end

  def add_a_donation_to(order, amount=30)
    d ||= BasicModels.donation(amount)
    order.add_item(d)
    d
  end

  describe 'new order' do
    subject { Order.new }
    its(:items) { should be_empty }
    its(:cart_items) { should be_empty }
    its(:total_price) { should be_zero }
    its(:purchased?) { should be_false }
    its(:refundable_to_credit_card?) { should be_false }
    its(:errors) { should be_empty }
  end

  describe 'cart' do
    before :each do ; @order = Order.new ; end
    it 'should be able to add items' do
      @i = Item.new
      @order.add_item(@i)
      @order.cart_items.should include(@i)
    end
    describe 'emptying cart' do
      it 'should work when cart contains items' do
        3.times { @order.add_item(Item.new) }
        @order.empty_cart!
        @order.should have(0).cart_items
      end
      it 'should work when cart is empty' do
        @order.empty_cart!
        @order.should have(0).cart_items
      end
    end
  end

  describe 'selecting only vouchers or donations' do
    before :each do
      @order = Order.new
      @v1,@v2 = Array.new(2) { add_a_voucher_to @order }
      @d1 = add_a_donation_to @order
    end
    describe 'selecting only vouchers' do
      subject { @order.cart_vouchers }
      it { should include(@v1) }
      it { should include(@v2) }
      it { should_not include(@d1) }
    end
    describe 'selecting only donations' do
      subject { @order.cart_donations }
      it { should include(@d1) }
      it { should_not include(@v1) }
      it { should_not include(@v2) }
    end
  end

  describe 'adding comment' do
    before :each do
      @order = Order.new
      @v1,@v2 = Array.new(2) { add_a_voucher_to @order }
      @v1.comments = 'comment'
      @d1 = add_a_donation_to @order
      @order.add_comment 'A comment'
    end
    it 'should not add comment to donation' do
      @d1.comments.should be_blank
    end
    it 'should add comment to all vouchers' do
      @v1.comments.should == 'comment; A comment'
      @v2.comments.should == 'A comment'
    end
  end
  
  describe 'checking if ready for purchase' do
    before :each do
      @valid_order = Order.new
      @valid_order.add_item(Item.new)
      @valid_order.customer = BasicModels.create_generic_customer
      @valid_order.recipient = BasicModels.create_generic_customer
    end
    
  end
  
end
