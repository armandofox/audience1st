require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include ActiveMerchant::Billing

describe Store, "Purchasing" do
  self.use_transactional_fixtures = false # to test if rollback works
  
  context "with credit card" do
    before(:each) do
      @amount = 12.35
      @success = ActiveMerchant::Billing::Response.new(true, "Success",
        :transaction_id => "999")
      @failure = ActiveMerchant::Billing::Response.new(false, "Failure")
      @bill_to = Customer.create!(:first_name => "John",
        :last_name => "Doe", :street => "123 Fake St",
        :email => "john@yahoo.com", :day_phone => "212-555-5555",
        :city => "New York", :state => "NY", :zip => "10019")
      @order_num = "789"
      @cc = CreditCard.new(:first_name => @bill_to.first_name,
        :last_name => @bill_to.last_name,
        :month => "12", :year => "2020", :verification_value => "999")
      @cc_params = {:credit_card => @cc,
            :bill_to => @bill_to, :order_number => @order_num}
      @params = {:order_id => @order_num, :email => @bill_to.email,
        :billing_address => {:name => @bill_to.full_name,
          :address1 => @bill_to.street, :city => @bill_to.city,
          :state => @bill_to.state, :zip => @bill_to.zip,
          :phone => @bill_to.day_phone, :country => 'US'}}
    end
    after(:each) do
      @bill_to.destroy
    end
    it "should route to the credit card payment method" do
      Store.should_receive(:purchase_with_credit_card!)
      Store.purchase!(:credit_card, @amount, {}) do
      end
    end
    it "should call the gateway with correct payment info" do
      Store.should_receive(:pay_via_gateway).with(@amount,@cc, @params).
        and_return(@success)
      Store.purchase!(:credit_card, @amount, @cc_params) do
      end
    end
    context "successfully" do
      it "should record side effects to the database"  do
        Store.should_receive(:pay_via_gateway).with(@amount,@cc, @params).
          and_return(@success)
        Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "New@email.com"
          @bill_to.save!
        end
        @bill_to.email.should == "New@email.com"
      end
    end
    context "unsuccessfully" do
      it "should not perform side effects if purchase fails"  do
        old_email = @bill_to.email
        Store.should_receive(:pay_via_gateway).with(@amount,@cc,@params).
          and_return(@failure)
        Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "Change@email.com"
        end
        @bill_to.reload
        @bill_to.email.should == old_email
      end
      it "should not do purchase if side effects fail" do
        Store.should_not_receive(:pay_via_gateway)
        Store.purchase!(:credit_card, @amount, @cc_params) do
          raise "Boom!"
        end
      end
      it "should not change the database if side effects fail" do
        old_email = @bill_to.email
        Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "InvalidEmail"
          @bill_to.save!
        end
        @bill_to.email.should == old_email
      end
    end
  end

  context "with cash" do
    it "should not perform side effects if purchase fails" 
    it "should not do purchase if side effects fail"
  end

  end
