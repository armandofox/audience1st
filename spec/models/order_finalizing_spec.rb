require 'spec_helper'

describe Order, 'finalizing' do
  # Simplify matching Customer vouchers for a particular showdate and vouchertype
  class Customer < ActiveRecord::Base
    def vouchers_for(showdate, vouchertype)
      self.vouchers.find_all_by_showdate_id_and_vouchertype_id(showdate.id, vouchertype.id)
    end
  end

  before :each do                # set these up so they're not rolled back by transaction around each example, since we test transactions in credit-card-failure case
    @vt = BasicModels.create_revenue_vouchertype(:price => 7)
    @sd = BasicModels.create_one_showdate(1.day.from_now)
    @vv = ValidVoucher.create!(
      :vouchertype => @vt, :showdate => @sd, :start_sales => Time.now, :end_sales => 10.minutes.from_now,
      :max_sales_for_type => 100)
    @vt2 = BasicModels.create_revenue_vouchertype(:price => 3)
    @sd2 = BasicModels.create_one_showdate(1.week.from_now)
    @vv2 = ValidVoucher.create!(
      :vouchertype => @vt2, :showdate => @sd2, :start_sales => Time.now, :end_sales => 10.minutes.from_now,
      :max_sales_for_type => 100)
    @the_processed_by = BasicModels.create_generic_customer
    @the_customer = BasicModels.create_generic_customer
    @the_purchaser = BasicModels.create_generic_customer
    @order = Order.new(:processed_by => @the_processed_by)
    @donation = BasicModels.donation(17)
  end

  after :each do
    [@vt, @sd, @vv, @vt2, @sd2, @vv2, @the_processed_by].each { |m| m.destroy rescue nil }
  end

  describe 'pre-purchase checks' do
    before :each do
      @order.add_tickets(@vv, 2)
      @order.customer = @the_customer
      @order.purchaser = @the_purchaser
      @order.processed_by = @the_processed_by
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
    it 'should fail if contains a course enrollment without enrollee name' do
      @order.comments = nil
      @order.stub!(:contains_enrollment?).and_return(true)
      verify_error /You must specify the enrollee's name for classes/ # '
    end
  end

  context 'when not ready' do
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
        @order.add_tickets(@vv,1)
        lambda { @order.finalize! }.should raise_error
      end
    end
  end

  context 'successful' do
    before :each do
      @cust = @the_customer
      @cust.items.delete_all
      @order = Order.new(
        :purchasemethod => Purchasemethod.default,
        :processed_by   => @the_processed_by,
        :customer       => @cust,
        :purchaser      => @cust,
        :comments       => 'Comment'
        )
      @order.add_tickets(@vv,2)
      @order.add_tickets(@vv2,1)
      @order.add_donation(@donation)
      Store.should_not_receive(:pay_with_credit_card) # stub this out, it has its own tests
    end
    describe 'web order' do
      shared_examples_for 'when valid' do
        it 'should be saved' do ; @order.should_not be_a_new_record ; end
        it 'should include the items' do ; @order.should have(4).items ; end
        it 'should have a sold-on time' do ;@order.sold_on.should be_between(Time.now - 5.seconds, Time.now) ; end
        it 'should set purchasemethod on its items' do ; @order.items.each { |i| i.purchasemethod.should == @order.purchasemethod } ; end
        it 'should set order ID on its items' do ; @order.items.each { |i| i.order_id.should == @order.id } ; end
        it 'should set sold-on time on its items' do ; @order.items.each { |i| i.sold_on.should be_a_kind_of(Time) } ; end
        it 'should set comments on its items' do ; @order.items.each { |i| i.comments.should == 'Comment' } ; end
        it 'should add vouchers to customer account' do
          @cust.should have(2).vouchers_for(@sd,@vt)
          @cust.should have(1).vouchers_for(@sd2,@vt2)
        end
        it 'should compute total price successfully' do ; @order.reload.total_price.should == 34 ; end
      end
      context 'when purchaser==recipient' do
        before :each do ; @order.finalize! ; end
        it_should_behave_like 'when valid'
        it 'should add donations to customer account' do ; @cust.donations.should include(@donation) ; end
        it 'should leave gift_purchaser nil on all vouchers' do ; @cust.vouchers.each { |v| v.gift_purchaser.should be_nil } ; end
      end
      context 'when purchaser!=recipient' do
        before :each do ;   @order.purchaser = @purch = @the_purchaser ; @order.finalize! ; end
        it_should_behave_like 'when valid'
        it 'should set gift_purchaser_id on all vouchers' do ; @cust.vouchers.each { |v| v.gift_purchaser_id.should == @purch.id } ; end
        it 'should add donations to purchaser account' do ; @purch.donations.should include(@donation) ; end
        it 'should NOT add donations to recipient account' do ; @cust.donations.should_not include(@donation) ; end
        it 'should NOT add vouchers to purchaser account' do
          @purch.vouchers.should have(0).vouchers_for(@sd,@vt)
          @purch.vouchers.should have(0).vouchers_for(@sd2,@vt2)
        end
      end
    end
    describe 'walkup order'  do
      before :each do
        Customer.walkup_customer.vouchers.delete_all
        @order.purchaser = @order.customer = Customer.walkup_customer
        @order.walkup = true
        @order.finalize!
      end
      it 'should assign all vouchers to walkup customer' do ; Customer.walkup_customer.should have(3).vouchers ; end
      it 'should mark all vouchers as walkup' do ; Customer.walkup_customer.vouchers.all? { |v| v.walkup? }.should be_true ; end
    end
  end
  describe 'web order with FAILED credit card payment' do
    before :each do
      @the_customer.items.delete_all
      @order = Order.new(
        :purchasemethod => mock_model(Purchasemethod, :purchase_medium => :credit_card),
        :processed_by   => @the_customer,
        :customer       => @the_customer,
        :purchaser      => @the_customer
        )
      @order.stub!(:ready_for_purchase?).and_return(true)
      @order.add_tickets(@vv,2)
      @order.add_tickets(@vv2,1)
      @order.add_donation(@donation)
      @previous_vouchers_count = Voucher.count
      @previous_donations_count = Donation.count
      Store.stub(:pay_with_credit_card).and_return(nil)
      lambda { @order.finalize! }.should raise_error(Order::PaymentFailedError)
    end
    it 'should leave authorization field blank' do
      @order.authorization.should be_blank
    end
    it 'should not save the items' do
      Voucher.count.should == @previous_vouchers_count
      Donation.count.should == @previous_donations_count
    end
    it 'should not add vouchers to customer' do ; @the_customer.reload.should have(0).vouchers ; end
    it 'should not complete the order' do ; @order.should_not be_completed ; end
  end
end
