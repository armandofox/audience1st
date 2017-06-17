require 'rails_helper'

describe StoreController do
  fixtures :customers
  fixtures :purchasemethods
  before :each do ; @buyer = create(:customer) ;  end
  
  shared_examples_for 'initial visit' do
    before :each do
      @r = {:controller => 'store', :action => 'index'}
      @c = create(:customer)
      @anon = Customer.anonymous_customer
      @extra = {:show_id => '25', :promo_code => 'x'}.merge(@extra ||= {})
    end
    context 'when not logged in' do
      before :each do ; login_as(nil) ; end
      it 'redirects as generic customer' do
        get :index
        response.should redirect_to_path(store_path(@anon))
      end
      it 'preserves params' do
        get :index, @extra
        response.should redirect_to_path(store_path(@anon, @extra))
      end

      it 'prevents switching to a different user' do
        get :index, {:customer_id => @c.id}
        response.should redirect_to_path(store_path(@anon))
      end
    end
    context 'when logged in as regular user' do
      before :each do ; login_as(@c) ;  end
      it 'redirects to your login keeping params' do
        get :index, @extra
        response.should redirect_to_path(store_path(@c, @extra))
      end
      it 'prevents you from switching to different user' do
        other = create(:customer)
        get :index, @extra.merge(:customer_id => other)
        response.should redirect_to_path(store_path(@c, @extra))
      end
      it 'lets you view store as yourself' do
        get :index, @extra.merge(:customer_id => @c)
        response.should be_success
      end
    end
    context 'when logged in as admin' do
      before :each do ; login_as(@b = customers(:boxoffice_user)) ; end
      it 'redirects to you if no customer specified' do
        get :index, @extra
        response.should redirect_to_path(store_path(@b,@extra))
      end
      it 'redirects to another customer' do
        get :index, @extra.merge(:customer_id => @c)
        response.should be_success
      end
    end
  end

  context 'initial visit' do
    describe 'to :index' do
      before :each do ; @action = :index ; end
      it_should_behave_like 'initial visit'
    end
    describe 'to :subscribe' do
      before :each do ; @action = :subscribe ; end
      it_should_behave_like 'initial visit'
    end
    describe 'to :donate_to_fund' do
      before :each do ; @action = :donate_to_fund ; @extras = {:id => mock_model(AccountCode)}; end
      it_should_behave_like 'initial visit'
    end
  end

  describe "on InvalidAuthenticityToken exception" do
    before(:each) do
      @controller.allow_forgery_protection = true
    end
    it 'should check the authenticity token' do
      @controller.should_receive(:verify_authenticity_token)
      post :place_order, {:customer_id => @buyer.id, :authenticity_token => 'wrong'}
    end
    it "should show the Session Expired page rather than throwing error" do
      @controller.should_receive(:verify_authenticity_token).and_raise ActionController::InvalidAuthenticityToken
      post :place_order, {:customer_id => @buyer.id, :authenticity_token => 'wrong'}
      response.should render_template 'messages/session_expired'
    end
  end

  describe 'quick donation' do
    before :each do
      @new_valid_customer = {
        :first_name => 'Joe', :last_name => 'Mallon',
        :street => '123 Fake St', :city => 'Oakland', :state => 'CA',
        :zip => '94111', :day_phone => '510-999-9999', :eve_phone => '333-3333'}
    end
    shared_examples_for 'failure' do
      before :each do ; @count = Customer.count(:all) ; end
      it 'redirects' do ; response.should render_template 'store/donate' ;  end
      it 'shows error messages' do ; render_multiline_message(flash[:alert]).should match(@alert) ; end
      it 'does not create new customer' do ; Customer.count(:all).should == @count ; end
    end
    context 'with invalid donation amount' do
      before :each do
        @count = Customer.count(:all)
        @alert = /Donation amount must be provided/
        post :donate, {:customer => @new_valid_customer}
      end
      it_should_behave_like 'failure'
    end
    context 'when new customer not valid as purchaser' do
      before :each do
        @new_valid_customer.delete(:city)
        @alert = /Incomplete or invalid donor information:/
        post :donate, {:customer => @new_valid_customer, :donation => 5, :credit_card_token => 'dummy'}
      end
      it_should_behave_like 'failure'
    end
    context 'when credit card token invalid' do
      before :each do
        @alert = /Invalid credit card transaction/
        Stripe::Charge.stub(:create).and_raise(Stripe::StripeError)
        post :donate, {:customer => @new_valid_customer, :donation => 5}
      end
      it_should_behave_like 'failure'
    end
    
  end
  describe "processing empty cart" do
    before :each do
      login_as @buyer
    end
    context "and no donation" do
      shared_examples_for "all cases" do
        it "should redirect to index" do
          post :process_cart, {:customer_id => @buyer.id}
          response.should redirect_to store_path(@buyer)
        end
        it "should display a warning" do
          post :process_cart, {:customer_id => @buyer.id}
          flash[:alert].should match(/nothing in your order/i)
        end
      end
      context "if gift" do
        before do ; @params = {:gift => '1'} ; end
        it_should_behave_like "all cases"
      end
      context "if nongift" do
        before do ; @params = {} ; end
        it_should_behave_like "all cases"
      end
    end
    context "with donation" do
      before(:each) do
        @params = {:customer_id => @buyer.id, :donation => "13"}
        @d = mock_model(Donation, :price => 13, :amount => 13, :account_code_id => 1).as_null_object
      end
      it "should allow proceeding" do
        post :process_cart, @params
        response.should redirect_to checkout_path(@buyer)
      end
      it "should proceed to checkout even if gift order" do
        @params[:gift] = 1
        post :process_cart, @params
        response.should redirect_to(:action => 'checkout')
      end
      it "should add the donation to the cart" do
        controller.stub!(:find_cart).and_return(@cart = Order.new)
        Donation.should_receive(:from_amount_and_account_code_id).with(13, nil, nil).and_return(d = Donation.new)
        @cart.should_receive(:add_donation).with(d)
        post :process_cart, @params
      end
    end

  end

  describe "landing page with show selected" do
    before(:each) do
      login_as @buyer
      @sd1 = create(:showdate, :thedate => 1.week.from_now)
      @sd2 = create(:showdate, :thedate => 4.weeks.from_now)
    end
    it "should select showdate if given" do
      get :index, {:customer_id => @buyer.id, :showdate_id => @sd2.id}
      assigns(:sd).id.should == @sd2.id
    end
    it "should default to earliest showdate with tickets if invalid" do
      get :index, {:customer_id => @buyer.id, :showdate_id => 9999999}
      assigns(:sd).id.should == @sd1.id
    end
  end

  describe "user-created gift recipient" do
    before(:each) do
      login_as @buyer
      @customer = {:first_name => "John", :last_name => "Bob",
        :street => "742 Evergreen Terrace", :city => "Springfield",
        :state => "IL", :zip => "09091"}
      controller.stub(:find_cart).and_return(mock_model(Order).as_null_object)
    end
    it "should be valid with only a phone number" do
      @customer[:day_phone] = "999-999-9999"
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      response.should redirect_to checkout_path(@buyer)
    end
    it "should be valid with only an email address" do
      @customer[:email] = "me@example.com"
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      response.should redirect_to checkout_path(@buyer)
    end
    it "should not be valid if neither phone nor email given" do
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      flash[:alert].should be_a_kind_of(Customer)
      response.should render_template(:shipping_address)
      response.should_not be_redirect
    end
  end

end
