require 'spec_helper'

describe Order do
  before :each do
    @the_customer = BasicModels.create_generic_customer
    @the_processed_by = BasicModels.create_generic_customer
    @order = Order.new(:processed_by => @the_processed_by)
  end
  describe 'new order' do
    subject { Order.new }
    it { should_not be_a_gift }
    it { should_not be_completed }
    it { should_not be_walkup }
    its(:items) { should be_empty }
    its(:cart_empty?) { should be_true }
    its(:total_price) { should be_zero }
    its(:refundable_to_credit_card?) { should be_false }
    its(:errors) { should be_empty }
    its(:comments) { should be_blank }
  end

  describe 'creating from bare donation' do
    before(:each) { @order = Order.new_from_donation(10.00, AccountCode.default_account_code, BasicModels.create_generic_customer) }
    it 'should not be completed' do ; @order.should_not be_completed ; end
    it 'should include a donation' do ; @order.include_donation?.should be_true  ; end
    it 'should_not be_a_gift' do ; @order.should_not be_a_gift ; end
    it 'should not be ready' do ; @order.should_not be_ready_for_purchase, @order.errors.full_messages ; end
    it 'should be ready when purchasemethod and processed_by are set' do
      @order.purchasemethod = Purchasemethod.default
      @order.processed_by = @the_customer
      @order.should be_ready_for_purchase
    end
  end
end
