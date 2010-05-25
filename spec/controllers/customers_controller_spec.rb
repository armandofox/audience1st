require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CustomersController do
  include AuthenticatedSystem
  describe "admin switching" do
    before(:each) do
      @admin = BasicModels.create_customer_by_role(:boxoffice_manager)
      login_as @admin
      current_user.id.should == @admin.id
    end
    context "to existing user" do
      before(:each) do
        @customer = BasicModels.create_generic_customer
      end
      it "should switch to new user" do
        get :switch_to, :id => @customer.id, :target_controller => :customers, :target_action => :welcome
        current_user.id.should == @customer.id
      end
      it "should retain current admin"
    end
  end
  describe "checkout flow" do
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

  
