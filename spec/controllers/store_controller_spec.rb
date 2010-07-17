require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StoreController do

  describe "trying to proceed with empty cart" do
    context "and no donation" do
      describe "all cases", :shared => true do
        it "should redirect to index" do
          post 'shipping_address', @params
          response.should redirect_to(:action => 'index')
        end
        it "should display a warning" do
          post 'shipping_address', @params
          flash[:warning].should match(/please select a show date and tickets/i)
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
        @d = mock_model(Donation, :price => 13, :amount => 13)
      end
      it "should allow proceeding" do
        post 'shipping_address', @params
        response.should redirect_to(:action => 'checkout'), flash[:warning]
      end
      it "should proceed to checkout even if gift order" do
        post 'shipping_address', :donation => '13', :gift => '1'
        response.should redirect_to(:action => 'checkout')
      end
      it "should create the donation" do
        Donation.should_receive(:online_donation).with(13, @c.id, @l.id).and_return(@d)
        post 'shipping_address', @params
      end
      it "should add the donation to the cart" do
        controller.stub!(:find_cart).and_return(@cart = Cart.new)
        Donation.stub!(:online_donation).and_return(@d)
        @cart.should_receive(:add).with(@d)
        post 'shipping_address', @params
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

  describe "online purchase" do
    describe "generally", :shared => true do
    end
    describe "for self" do
      it_should_behave_like "generally"
      it "should associate the ticket with the buyer"
    end
    describe "as gift" do
      it_should_behave_like "generally"
      it "should associate the ticket with the gift recipient"
      it "should identify the buyer as the gift purchaser"
    end
  end

end
