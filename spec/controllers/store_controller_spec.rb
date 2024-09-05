# coding: utf-8
require 'rails_helper'

describe StoreController do
  before :each do ; @buyer = create(:customer) ;  end

  shared_examples_for 'initial visit' do
    before :each do
      @r = {:controller => 'store', :action => 'index'}
      @c = create(:customer)
      @anon = Customer.anonymous_customer
      @extra = {:show_id => '25', :promo_code => 'x'}.merge(@extra ||= {})
    end
    context 'when not logged in' do
      before :each do
        login_as(nil)
      end
      it 'redirects as generic customer' do
        get :index
        expect(response).to redirect_to(store_path(@anon))
      end
      it 'preserves params' do
        get :index, @extra
        expect(response).to redirect_to(store_path(@anon, @extra))
      end

      it 'prevents switching to a different user' do
        get :index, {:customer_id => @c.id}
        expect(response).to redirect_to(store_path(@anon))
      end
    end
    context 'when logged in as regular user' do
      before :each do
        login_as(@c)
      end
      it 'redirects to your login keeping params' do
        get :index, @extra
        expect(response).to redirect_to(store_path(@c, @extra))
      end
      it 'prevents you from switching to different user' do
        other = create(:customer)
        get :index, @extra.merge(:customer_id => other)
        expect(response).to redirect_to(store_path(@c, @extra))
      end
      it 'lets you view store as yourself' do
        get :index, @extra.merge(:customer_id => @c.id)
        expect(response).to be_success
      end
      it 'redirects if URL explicitly mentions anonymous customer' do
        get :index, @extra.merge(:customer_id => Customer.anonymous_customer.id)
        expect(response).to redirect_to(store_path(@c, @extra))
      end
    end
    context 'when logged in as admin' do
      before :each do
        @b = create(:boxoffice_manager)
        login_as @b
      end
      it 'redirects to you if no customer specified' do
        get :index, @extra
        expect(response).to redirect_to(store_path(@b,@extra))
      end
      it 'redirects to another customer' do
        get :index, @extra.merge(:customer_id => @c)
        expect(response).to be_success
      end
      it 'redirects to logged-in staff if URL explicitly mentions anonymous customer' do
        get :index, @extra.merge(:customer_id => Customer.anonymous_customer.id)
        expect(response).to redirect_to(store_path(@b, @extra))
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
  end

  describe "on InvalidAuthenticityToken exception" do
    before(:each) do
      controller.allow_forgery_protection = true
    end
    it 'should check the authenticity token' do
      expect(controller).to receive(:verify_authenticity_token)
      post :place_order, {:customer_id => @buyer.id, :authenticity_token => 'wrong'}
    end
    it "should show the Session Expired page rather than throwing error" do
      expect(controller).to receive(:verify_authenticity_token).and_raise ActionController::InvalidAuthenticityToken
      post :place_order, {:customer_id => @buyer.id, :authenticity_token => 'wrong'}
      expect(response).to render_template 'components/session_expired'
    end
  end

  describe 'GET  #donate_to_fund_redirect' do
  before :each do
    @new_account_code = create(:account_code, id: 2)
    @anon = Customer.anonymous_customer
  end
  it 'redirects to donate route with fund code' do
    fund_code = @new_account_code.code
    get :donate_to_fund_redirect, {:id => fund_code, :customer_id => @anon}
    expect(response).to redirect_to(quick_donate_path(account_code_string: fund_code))
  end
  it 'sets the fund code to default code when it is missing' do
    get :donate_to_fund_redirect, { :customer_id => @anon }
    expect(response).to redirect_to(quick_donate_path(account_code_string: Donation.default_code.code))
  end
  it 'sets the fund code to default code when it is invalid' do
    invalid_fund_code = ' '
    get :donate_to_fund_redirect, { id: invalid_fund_code, :customer_id => @anon }
    expect(response).to redirect_to(quick_donate_path(account_code_string: Donation.default_code.code))
  end
end

  describe 'quick donation with nonexistent customer' do
    before :each do
      @new_valid_customer = attributes_for(:customer).except(:password,:password_confirmation)
    end
    context 'when credit card token invalid' do
      before(:each) do
        allow(Stripe::Charge).to receive(:create).and_raise(Stripe::StripeError)
      end
      it 'redirects having created the customer' do
        post :process_donation, {:customer => @new_valid_customer, :donation => 5, :credit_card_token => 'dummy'}
        created_customer = Customer.find_by!(:email => @new_valid_customer[:email])
        expect(response).to redirect_to(quick_donate_path(:donation => 5, :customer_id => created_customer.id, :account_code_string => Donation.default_code.code))
      end
      it 'shows error message' do
        post :process_donation, {:customer => @new_valid_customer, :donation => 5, :credit_card_token => 'dummy'}
        expect(flash[:alert]).to match(/credit card payment error/i)
      end
    end
    context 'with invalid donation amount' do
      it 'redirects having created the customer' do
        post :process_donation, {:customer => @new_valid_customer, :credit_card_token => 'dummy'}
        created_customer = Customer.find_by!(:email => @new_valid_customer[:email])
        expect(response).to redirect_to(quick_donate_path(:donation => 0, :customer_id => created_customer.id, :account_code_string => Donation.default_code.code))
      end
      it 'shows error message' do
        post :process_donation, :customer => @new_valid_customer, :credit_card_token => 'dummy'
        expect(flash[:alert]).to match(/donation amount must be provided/i)
      end
    end
    context 'when new customer not valid as purchaser' do
      before(:each) do
        @invalid_customer = attributes_for(:customer).except(:city,:state)
        @params = {:customer => @invalid_customer, :donation => 5, :credit_card_token => 'dummy', :account_code_string => Donation.default_code.code}
      end
      it 'does not create new customer' do
        expect { post :process_donation, @params }.not_to change { Customer.all.size }
      end
      it 'redirects preserving customer info' do
        post :process_donation, @params
        expect(response).to redirect_to(quick_donate_path(@params.except(:credit_card_token)))
      end
      it 'shows error' do
        post :process_donation, @params
        expect(flash[:alert]).to match(/Incomplete or invalid donor/i)
      end
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
          expect(response).to redirect_to store_path(@buyer)
        end
        it "should display a warning" do
          post :process_cart, {:customer_id => @buyer.id}
          expect(flash[:alert]).to match(/no items in your order/i)
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
        expect(response).to redirect_to checkout_path(@buyer)
      end
      it "should proceed to checkout even if gift order" do
        @params[:gift] = 1
        post :process_cart, @params
        expect(response).to redirect_to(:action => 'checkout')
      end
      xit "should add the donation to the cart" do
        allow(controller).to receive(:find_cart).and_return(@order = create(:order))
        expect(Donation).to receive(:from_amount_and_account_code_id).with(13, nil, nil).and_return(d = Donation.new)
        expect(@order).to receive(:add_donation).with(d)
        post :process_cart, @params
        expect(controller.find_cart)
      end
    end

  end

  specify 'cannot add tickets without seats if reserved seating' do
    @vv = create(:valid_voucher, :showdate => (@sd = create(:reserved_seating_showdate)))
    @customer = create(:customer)
    @params = {
      'seats' => '',
      "utf8"=>"✓",
      "showdate_id"=>@sd.id.to_s,
      "what"=>"", "referer"=>"index", "promo_code"=>"",
      "show"=>@sd.show_id.to_s,
      "showdate"=>@sd.id.to_s,
      "valid_voucher"=>{@vv.id.to_s=>"2"},
      "price"=>{@vv.id.to_s=>@vv.vouchertype.price.to_s}, "donation"=>"", "zone"=>"",
      "commit"=>"Continue to Billing Information",
      "customer_id"=>@customer.id.to_s
    }
    allow(controller).to receive(:add_retail_items_to_cart)
    allow(controller).to receive(:add_donation_to_cart)
    allow(controller).to receive(:current_user).and_return(@customer)
    post :process_cart, @params
    expect(flash[:alert]).to match(/seat can't be blank/i)
  end

  describe 'redirect if error adding to cart' do
    before(:each) do
      allow(controller).to receive(:add_retail_items_to_cart)
      allow(controller).to receive(:add_donation_to_cart)
      allow_any_instance_of(Order).to receive(:errors).and_return(['Error']) # make #empty? false
      3.times { create(:showdate) }
      @sd = create(:showdate).id # so it's not the first one
      @anon = Customer.anonymous_customer.id
    end
    it 'redirects to correct showdate' do
      post :process_cart, {:referer => 'index', :customer_id => @anon, :showdate_id => @sd}
      expect(response).to redirect_to(store_path(:customer_id => @anon, :showdate_id => @sd))
    end
  end

  describe "user-created gift recipient" do
    before(:each) do
      login_as @buyer
      @customer = {:first_name => "John", :last_name => "Bob",
        :street => "742 Evergreen Terrace", :city => "Springfield",
        :state => "IL", :zip => "09091"}
      o = double('Order', :cart_empty? => false).as_null_object
      allow(controller).to receive(:find_cart).and_return(o)
    end
    it "should be valid with only a phone number" do
      @customer[:day_phone] = "999-999-9999"
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      expect(response).to redirect_to checkout_path(@buyer)
    end
    it "should be valid with only an email address" do
      @customer[:email] = "me@example.com"
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      expect(response).to redirect_to checkout_path(@buyer)
    end
    it "should not be valid if neither phone nor email given" do
      post :shipping_address, {:customer_id => @buyer.id, :customer => @customer}
      expect(flash[:alert]).to match(/at least one phone number or email/i)
      expect(response).to render_template(:shipping_address)
      expect(response).not_to be_redirect
    end
  end

end
