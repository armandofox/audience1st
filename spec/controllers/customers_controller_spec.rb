require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CustomersController do
  include AuthenticatedSystem
  context "during checkout flow" do
    before(:each) do
      @customer = BasicModels.create_generic_customer
      login_as @customer
      ApplicationController.stub!(:find_cart).and_return(mock_model(Cart).as_null_object)
      controller.set_checkout_in_progress(true)
      @target = {:controller => 'store', :action => 'checkout'}
      set_return_to @target
    end
    describe "when updating billing info" do
      before(:each) do
        params = {:id => @customer, :customer => {:street => "100 Embarcadero",   :zip => "94100",
            :email => "nobody@noplace.com"}}
        post :edit, params
      end
      it "should not update the password" do
        @customer.crypted_password_changed?.should be_false
      end
      it "should update the address" do
        @customer.reload
        @customer.street.should == "100 Embarcadero"
        @customer.zip.should == "94100"
      end
      it "should display a message confirming the update" do
        flash[:notice].should contain("Contact information was successfully updated")
      end
      it "should continue the checkout flow" do
        response.should redirect_to(@target)
      end
    end
  end
end

  
