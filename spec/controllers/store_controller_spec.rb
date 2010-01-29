require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StoreController do

  describe "trying to proceed with empty cart" do
    context "and no donation" do
      describe "all cases", :shared => true do
        it "should redirect to index" do
          post 'shipping_address'
          response.should redirect_to(:action => 'index')
        end
        it "should display a warning" do
          post 'shipping_address'
          flash[:warning].should match(/please select a show date and tickets/i)
        end
      end
      context "if gift" do ; it_should_behave_like "all cases" ; end
      context "if nongift" do ; it_should_behave_like "all cases"; end
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
      context "gift order" do ; it_should_behave_like "always" ; end
      context "nongift order" do ; it_should_behave_like "always" ; end
    end
  end

  describe "completing billing address" do
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
