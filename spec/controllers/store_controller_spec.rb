require 'spec_helper'

describe StoreController do
  fixtures :customers

  describe "on InvalidAuthenticityToken exception" do
    before(:each) do
      @controller.allow_forgery_protection = true
    end
    it 'should check the authenticity token' do
      @controller.should_receive(:verify_authenticity_token)
      post :place_order, :authenticity_token => 'wrong'
    end
    it "should show the Session Expired page rather than throwing error" do
      @controller.should_receive(:verify_authenticity_token).and_raise ActionController::InvalidAuthenticityToken
      post :place_order, :authenticity_token => 'wrong'
      response.should render_template 'messages/session_expired'
    end
  end
  describe 'promo redemption redirect' do
    it 'redirects to correct page' do
      post :process_cart, {:promo_code => 'xyz', :commit => 'Redeem'}
      response.should redirect_to(:action => :index)
    end
    it 'remembers promo code'
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
      it 'shows appropriate message' do ; flash[:alert].should match(@alert) ; end
      it 'does not create new customer' do ; Customer.count(:all).should == @count ; end
    end
    context 'with invalid donation amount' do
      before :each do
        @count = Customer.count(:all)
        @alert = /Donation amount must be provided/
        post :process_quick_donation, {:customer => @new_valid_customer}
      end
      it_should_behave_like 'failure'
    end
    context 'when new customer not valid as purchaser' do
      before :each do
        @new_valid_customer.delete(:city)
        @alert = /Incomplete or invalid donor information:/
        post :process_quick_donation, {:customer => @new_valid_customer, :donation => 5, :credit_card_token => 'dummy'}
      end
      it_should_behave_like 'failure'
    end
    context 'when credit card token invalid' do
      before :each do
        @alert = /Invalid credit card transaction/i
        post :process_quick_donation, {:customer => @new_valid_customer, :donation => 5}
      end
      it_should_behave_like 'failure'
    end
    
  end
  describe "processing empty cart" do
    before :each do ; request.env['HTTP_REFERER'] = '/store' ; end
    context "and no donation" do
      shared_examples_for "all cases" do
        it "should redirect to index" do
          post 'process_cart', @params
          response.should redirect_to(:action => 'index')
        end
        it "should display a warning" do
          post 'process_cart', @params
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
        @params = {:donation => "13"}
        controller.stub!(:store_customer).and_return(@c = mock_model(Customer))
        controller.stub!(:logged_in_id).and_return((@l = mock_model(Customer)).id)
        @d = mock_model(Donation, :price => 13, :amount => 13, :account_code_id => 1)
      end
      it "should allow proceeding" do
        post 'process_cart', @params
        response.should redirect_to(:action => 'checkout')
      end
      it "should proceed to checkout even if gift order" do
        post 'process_cart', :donation => '13', :gift => '1'
        response.should redirect_to(:action => 'checkout')
      end
      it "should create donation with no account code" do
        Donation.should_receive(:from_amount_and_account_code_id).with(13, nil).and_return(@d)
        post 'process_cart', @params
      end
      it 'should create donation with nondefault account code when supplied' do
        @params[:account_code_id] = 75
        Donation.should_receive(:from_amount_and_account_code_id).with(13, '75').and_return(@d)
        post 'process_cart', @params
      end
      it "should add the donation to the cart" do
        controller.stub!(:find_cart).and_return(@cart = Order.new)
        Donation.should_receive(:from_amount_and_account_code_id).with(13, nil).and_return(d = Donation.new)
        @cart.should_receive(:add_donation).with(d)
        post 'process_cart', @params
      end
    end

  end
  describe "proceeding with nonempty cart" do
    context "with valid tickets" do
      context "gift order" do
      end
      context "nongift order" do
      end
    end
    context "with invalid tickets" do
      describe "always", :shared => true do
        it "should redirect to the index page"
      end
      context "gift order" do
        before do ; @params = {:gift => '1'} ; end
        it_should_behave_like "always"
      end
      context "nongift order" do
        before do ; @params = {} ; end
        it_should_behave_like "always"
      end
    end
  end

  describe "completing billing address" do
  end

  describe "identifying gift recipient" do
    describe "from session" do
      before :each do
        StoreController.send(:public, :recipient_from_session)
        @rec = BasicModels.create_generic_customer
        session[:recipient_id] = @rec.id.to_s
      end
      it "should find valid recipient" do
        @controller.recipient_from_session.should == @rec
      end
      it "should update valid recipient's attributes" do
        attrs = {:street => '999 Broadway', :city => 'San Francisco'}
        @controller.params[:customer] = attrs
        r = @controller.recipient_from_session
        r.street.should == attrs[:street]
        r.city.should == attrs[:city]
      end
      it "should be nil if recipient from session doesn't exist" do
        session[:recipient_id] = 7979797979
        @controller.recipient_from_session.should be_nil
      end
    end
    describe "from supplied customer info" do
      before :all do ; StoreController.send(:public, :recipient_from_params) ; end
      it "should return customer if unique & valid gift recipient" do
        m = mock_model(Customer, :valid_as_gift_recipient? => true)
        Customer.should_receive(:find_unique).and_return(m)
        @controller.recipient_from_params.should == m
      end
      it "should not return customer if no unique match" do
        Customer.should_receive(:find_unique).and_return nil
        @controller.recipient_from_params.should be_nil
      end
      it "should not return customer if not valid gift recipient" do
        m = mock_model(Customer, :valid_as_gift_recipient? => nil)
        Customer.should_receive(:find_unique).and_return(m)
        @controller.recipient_from_params.should be_nil
      end
    end
  end

  describe "landing page" do
    before(:each) do
      @dt1 = "Jan 27, 2009, 8:00pm"
      @sd1 = BasicModels.create_one_showdate(Time.parse(@dt1))
      @dt2 = "Jan 29, 2009, 8:00pm"
      @sd2 = BasicModels.create_one_showdate(Time.parse(@dt2),100,@sd1.show)
    end
    it "should override valid date if showdate_id given" do
      get :index, :showdate_id => @sd1.id, :date => @dt2
      assigns(:sd).should == @sd1
    end
    it "should respect valid date" do
      pending 'Fix showdate_spec examples for Showdate.current_or_next'
      get :index, :date => @dt2
      assigns(:sd).should == @sd2
    end
    it "should default to earliest showdate with tickets if neither valid" do
      pending 'Fix showdate_spec examples for Showdate.current_or_next'
      get :index, :showdate_id => 9999999
      assigns(:sd).should == @sd2
    end
  end

  describe "successful order placement" do
    before(:each) do
    end
    describe "generally", :shared => true do
    end
    describe "for myself" do
      it_should_behave_like "generally"
      it "should associate the ticket with the buyer"
    end
    describe "as gift" do
      it_should_behave_like "generally"
      it "should associate the ticket with the gift recipient"
      it "should identify the buyer as the gift purchaser"
    end
  end

  describe "user-created gift recipient" do
    before(:each) do
      login_as(:tom)
      @controller.stub!(:recipient_from_params).and_return(nil)
      @customer = {:first_name => "John", :last_name => "Bob",
        :street => "742 Evergreen Terrace", :city => "Springfield",
        :state => "IL", :zip => "09091"}
      session[:recipient_id] = nil
      controller.stub(:find_cart).and_return(mock_model(Order).as_null_object)
    end
    it "should be valid with only a phone number" do
      @customer[:day_phone] = "999-999-9999"
      post :set_shipping_address, :customer => @customer
      flash[:alert].should be_blank, flash[:alert]
      response.should redirect_to(:action => 'checkout')
    end
    it "should be valid with only an email address" do
      @customer[:email] = "me@example.com"
      post :set_shipping_address, :customer => @customer
      flash[:alert].should be_blank
      response.should redirect_to(:action => 'checkout')
    end
    it "should not be valid if neither phone nor email given" do
      post :set_shipping_address, :customer => @customer
      flash[:alert].join(',').should match(/at least one phone number or email/i)
      response.should render_template(:shipping_address)
      response.should_not redirect_to(:action => :checkout)
    end
  end
end
