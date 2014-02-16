require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Store, "Purchasing" do
  self.use_transactional_fixtures = false # to test if rollback works
  before(:each) do
    @amount = 12.35
    @success = Store::BillingResponse.new(true, "Success",
      :transaction_id => "999")
    @failure = Store::BillingResponse.new(false, "Failure")
    @bill_to = BasicModels.create_generic_customer
    @order_num = "789"
    @cc = 'DummyCreditCardToken'
    @cc_params = {:credit_card_token => 'dummy',
      :bill_to => @bill_to, :order_number => @order_num}
  end
  after(:each) do
    @bill_to.destroy
  end

  describe "payment routing" do
    it "should route to correct handler for cash" do
      Store.should_receive(:purchase_with_cash!)
      Store.purchase!(:cash, @amount, {}) 
    end
    it "should route to correct handler for check" do
      Store.should_receive(:purchase_with_check!)
      Store.purchase!('check', @amount, {})
    end
    it "should return failure if payment method invalid" do
      @resp = Store.purchase!('foo', @amount, {}) 
      @resp.should be_a(Store::BillingResponse)
      @resp.should_not be_success
    end
    it "should return failure if params is nil" do
      @resp = Store.purchase!(:cash, @amount, nil)
      @resp.should be_a(Store::BillingResponse)
      @resp.should_not be_success
    end
  end
  
  context "with credit card" do
    it "should route to the credit card payment method" do
      Store.should_receive(:purchase_with_credit_card!)
      Store.purchase!(:credit_card, @amount, {}) do
      end
    end
    it "should call the gateway with correct payment info" do
      Stripe::Charge.should_receive(:create).
        with(hash_including(:amount => 100*@amount)).
        and_return(@success) 
      Store.purchase!(:credit_card, @amount, @cc_params) do
      end
    end

    context "successfully" do
      before :each do
        Stripe::Charge.should_receive(:create).once.and_return(@success)
      end
      it "should record side effects to the database"  do
        Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "New@email.com"
          @bill_to.save!
        end
        @bill_to.email.should == "New@email.com"
      end
      it "should return success" do
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
        end
        @resp.should be_a(Store::BillingResponse)
        @resp.should be_success
      end
    end
    context "unsuccessfully" do
      it "should not perform side effects if purchase fails"  do
        old_email = @bill_to.email
        Stripe::Charge.should_receive(:create).and_raise(Stripe::StripeError)
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "Change@email.com"
        end
        @bill_to.reload
        @bill_to.email.should == old_email
        @resp.should be_a(Store::BillingResponse)
        @resp.should_not be_success
      end
      it "should not do purchase if side effects fail" do
        Stripe::Charge.should_not_receive(:create)
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          raise "Boom!"
        end
        @resp.should be_a(Store::BillingResponse)
        @resp.should_not be_success
      end
      it "should not change the database if side effects fail" do
        old_email = @bill_to.email
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "InvalidEmail"
          @bill_to.save!
        end
        @bill_to.reload
        @bill_to.email.should == old_email
        @resp.should be_a(Store::BillingResponse)
        @resp.should_not be_success
      end
    end
  end

  context "with non-credit-card payment" do
    context "unsuccessfully" do
      describe "unsuccessful side effects",:shared=>true do
        it "should not change the database if side effects fail" do
          old_email = @bill_to.email
          Store.purchase!(@method, @amount, {}) do
            @bill_to.email = "InvalidEmailWillThrowError"
            @bill_to.save!
          end
          @bill_to.reload
          @bill_to.email.should == old_email
        end
        it "should return failure if side effects fail" do
          @resp = Store.purchase!(@method,@amount,@args) do
            raise "Boom!"
          end
          @resp.should be_a(Store::BillingResponse)
          @resp.should_not be_success
        end
      end
      describe "using cash" do
        before(:each) do ; @method = :cash ; end
        it_should_behave_like "unsuccessful side effects"
      end
      describe "using check" do
        before(:each) do ; @method = :check ; end
        it_should_behave_like "unsuccessful side effects"
      end
    end
    context "successfully" do
      it "should return success" do
        @resp = Store.purchase!(:cash,@amount,{})
        @resp.should be_a(Store::BillingResponse)
        @resp.should be_success
      end
      it "should change the database if side effects OK" do
        new_email = "valid@email.address.com"
        @resp = Store.purchase!(:cash,@amount,{}) do
          @bill_to.email = new_email
          @bill_to.save!
        end
        @bill_to.reload
        @bill_to.email.should == new_email
      end
    end
  end
end
