require 'spec_helper'
describe Order do
  before :each do ; @order = Order.new ; end
  
  def add_a_voucher_to(order)
    @vt ||= BasicModels.create_revenue_vouchertype
    @sd ||= BasicModels.create_one_showdate(1.day.from_now)
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
    it { should_not be_a_gift }
    it { should_not be_completed }
    its(:items) { should be_empty }
    its(:cart_items) { should be_empty }
    its(:total_price) { should be_zero }
    its(:refundable_to_credit_card?) { should be_false }
    its(:errors) { should be_empty }
  end

  describe 'cart' do
    it 'should be able to add items' do
      @i = Item.new
      @order.add_item(@i)
      @order.cart_items.should include(@i)
    end
    describe 'emptying' do
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
  
  describe 'pre-purchase checks' do
    before :each do
      2.times { add_a_voucher_to @order }
      add_a_donation_to @order
      @order.customer = BasicModels.create_generic_customer
      @order.purchaser = BasicModels.create_generic_customer
      @order.processed_by = BasicModels.create_generic_customer
      @order.purchasemethod = Purchasemethod.default
    end
    it 'should pass if all attributes valid' do
      @order.should be_ready_for_purchase
      @order.errors.should be_empty
    end
    def verify_error(regex)
      @order.should_not be_ready_for_purchase
      @order.errors.full_messages.should include_match_for(regex)
    end
    it 'should fail if no purchaser' do
      @order.purchaser = nil
      verify_error /No purchaser information/i
    end
    it 'should fail if purchaser invalid as purchaser' do
      @order.purchaser.stub(:valid_as_purchaser?).and_return(nil)
      @order.purchaser.stub_chain(:errors, :full_messages).and_return(['ERROR'])
      verify_error /ERROR/
    end
    it 'should fail if no recipient' do
      @order.customer = nil
      verify_error /No recipient information/
    end
    it 'should fail if zero amount for purchasemethod other than cash' do
      @order.stub(:total_price).and_return(0.0)
      @order.purchasemethod = mock_model(Purchasemethod, :purchase_medium => :check)
      verify_error /Zero amount/i
    end
    it 'should fail for credit card purchase with null token' do
      @order.purchasemethod = mock_model(Purchasemethod, :purchase_medium => :credit_card)
      @order.purchase_args = {:credit_card_token => nil}
      verify_error /Invalid credit card transaction/i
    end
    it 'should fail for credit card purchase with no token' do
      @order.purchasemethod = mock_model(Purchasemethod, :purchase_medium => :credit_card)
      @order.purchase_args = {}
      verify_error /Invalid credit card transaction/i
    end
    it 'should fail if recipient not a valid recipient' do
      @order.customer.stub(:valid_as_gift_recipient?).and_return(nil)
      @order.customer.stub_chain(:errors, :full_messages).and_return(['Recipient error'])
      verify_error /Recipient error/
    end
    it 'should fail if no purchase method' do
      @order.purchasemethod = nil
      verify_error /No payment method specified/i
    end
    it 'should fail if no processed-by' do
      @order.processed_by = nil
      verify_error /No information on who processed/i
    end
  end

  describe 'finalizing' do

    context 'when order is not ready' do
      it 'should fail if order is not ready for purchase' do
        @order.stub(:ready_for_purchase?).and_return(nil)
        lambda { @order.finalize! }.should raise_error(Order::NotReadyError)
      end
      describe 'should not update' do
        before(:each) do
          @order.stub(:ready_for_purchase?).and_return(true)
          @order.customer.stub(:add_items).and_raise(ActiveRecord::RecordInvalid) # force fail
        end
        it "completion status" do
          lambda { @order.finalize! }.should raise_error
          @order.should_not be_completed
        end
        it "items' properties" do
          v = add_a_voucher_to @order
          lambda { @order.finalize! }.should raise_error
          v.order_id.should be_nil
        end
      end
    end

    context 'when order is ready' do
      before :each do
        @cust = BasicModels.create_generic_customer
        @cust.vouchers.should be_empty
        @cust.donations.should be_empty
        @order = Order.new(
          :purchasemethod => Purchasemethod.default,
          :processed_by   => BasicModels.create_generic_customer,
          :customer       => @cust,
          :purchaser      => @cust
          )
        @v1,@v2 = Array.new(2) { add_a_voucher_to @order }
        @d1 = add_a_donation_to @order
      end
      shared_examples_for 'valid order processed' do
        before :each do
          Store.should_not_receive(:pay_with_credit_card) # stub this out, it has its own tests
          @order.finalize!
        end
        it 'should be saved' do ; @order.should_not be_a_new_record ; end
        it 'should include the items' do ; @order.should have(3).items ; end
        it 'should have a sold-on time' do ;@order.sold_on.should be_between(Time.now - 5.seconds, Time.now) ; end
        it 'should set purchasemethod on its items' do
          @order.items.each { |i| i.purchasemethod.should == @order.purchasemethod }
        end
        it 'should set order ID on its items' do
          @order.items.each { |i| i.order_id.should == @order.id }
        end
        it 'should set sold-on time on its items' do
          @order.items.each { |i| i.sold_on.should be_a_kind_of(Time) }
        end
        it 'should add vouchers to customer account' do
          @cust.vouchers.should include(@v1)
          @cust.vouchers.should include(@v2)
        end
      end
      context 'when purchaser==recipient' do
        it_should_behave_like 'valid order processed' 
        it 'should add donations to customer account' do
          @cust.donations.should include(@d1)
        end
        it 'should leave gift_purchaser nil on all vouchers' do
          [@v1,@v2].each { |v| v.gift_purchaser.should be_nil }
        end
      end
      context 'when purchaser!=recipient' do
        before :each do
          @purch = BasicModels.create_generic_customer
          @order.purchaser = @purch
        end
        it_should_behave_like 'valid order processed'
        it 'should set gift_purchaser_id on all vouchers' do
          [@v1,@v2].each { |v| v.gift_purchaser_id.should == @purch.id }
        end
        it 'should add donations to purchaser account' do ; @purch.donations.should include(@d1) ; end
        it 'should NOT add donations to recipient account' do ; @cust.donations.should_not include(@d1) ; end
        it 'should NOT add vouchers to purchaser account' do
          [@v1,@v2].each { |v| @purch.vouchers.should_not include(v) }
        end
      end
      context 'with credit card payment' do
        before :each do
          @order.purchasemethod = mock_model(Purchasemethod, :purchase_medium => :credit_card)
          @order.stub!(:ready_for_purchase?).and_return(true)
        end
        it 'succeeds' do
          Store.should_receive(:pay_with_credit_card).and_return(true)
          @order.finalize!
        end
        describe 'that fails' do
          before :each do
            Store.stub(:pay_with_credit_card).and_return(nil)
            lambda { @order.finalize! }.should raise_error(Order::PaymentFailedError)
          end
          it 'should leave authorization field blank' do
            @order.authorization.should be_blank
          end
          it 'should leave the ids of unsaved objects blank (Rails bug 2298)' do
            @order.cart_items.each { |e| e.id.should be_nil }
          end
          it 'should not save the items' do
            lambda { Voucher.find(@v1.id) }.should raise_error(ActiveRecord::RecordNotFound)
            lambda { Voucher.find(@v2.id) }.should raise_error(ActiveRecord::RecordNotFound)
          end
          it 'should reset new_record? to true (Rails bug 2298)' do
            @order.cart_items.each { |e| e.should be_a_new_record }
          end
          it 'should not add vouchers to customer' do ; @cust.should have(0).vouchers ; end
          it 'should not complete the order' do ; @order.should_not be_completed ; end
        end
      end
    end
  end
end
