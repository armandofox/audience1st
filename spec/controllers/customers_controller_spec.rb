require 'spec_helper'

describe CustomersController do
  before do
    CustomersController.send(:public, :current_user, :current_admin, :set_return_to)
  end
  describe "admin creating or updating valid customer" do
    fixtures :customers
    before(:each) do
      @params = BasicModels.new_generic_customer_params
      login_as :boxoffice_manager
      post :create, {:customer => @params}
    end
    it "should create the customer" do
      Customer.find_by_email(@params[:email]).should_not be_nil
    end
    it "should set created-by-admin flag" do
      Customer.find_by_email(@params[:email]).should be_created_by_admin
    end
    it "should not clear created-by-admin flag if admin updates record" do
      post :update, {:customer => {:first_name => 'Bobby'}}
      Customer.find_by_email(@params[:email]).should be_created_by_admin
    end
  end
  describe "user self-creation or self-update" do
    before(:each) do
      @params = BasicModels.new_generic_customer_params
      login_as(nil)
      post :user_create, {:customer => @params}
    end
    it "should create the customer" do
      Customer.find_by_email(@params[:email]).should_not be_nil
    end
    it "should not set created-by-admin flag when created by customer" do
      Customer.find_by_email(@params[:email]).should_not be_created_by_admin
    end
    describe "created-by-admin flag" do
      before(:each) do
        @customer = Customer.find_by_email(@params[:email])
        @customer.update_attribute(:created_by_admin, true)
      end
      it "should be cleared on successful update" do
        post :update, {:customer => {:first_name => "Bobby"}}
        @customer.reload
        @customer.should_not be_created_by_admin
      end
      it "should not be cleared if update fails" do
        post :update, {:customer => {:first_name => ''}}
        @customer.reload
        @customer.should be_created_by_admin
      end
    end
  end
  describe "admin switching" do
    before(:each) do
      @admin = BasicModels.create_customer_by_role(:boxoffice_manager,
        :last_name => "Admin" )
      @customer = BasicModels.create_generic_customer
      login_as @admin
      @controller.current_user.id.should == @admin.id
    end
    it "should switch to existing user" do
      get :switch_to, :id => @customer.id
      @controller.current_user.id.should == @customer.id
    end
    it "should retain current admin" do
      get :switch_to, :id => @customer.id
      @controller.current_admin.id.should == @admin.id
    end
    it "should not switch to nonexistent user" do
      id = @customer.id
      @customer.destroy
      get :switch_to, :id => id
    end
    it "should redirect to welcome action by default" do
      get :switch_to, :id => @customer.id
      response.should redirect_to(:controller => 'customers', :action => 'welcome')
    end
    it "should redirect to specified action if provided" do
      get :switch_to, :id => @customer.id, :target_controller => 'foo', :target_action => 'bar'
      response.should redirect_to(:controller => 'foo', :action => 'bar', :id => @customer.id)
    end
  end
  describe "checkout flow" do
    before(:each) do
      @customer = BasicModels.create_generic_customer
      login_as @customer
      ApplicationController.stub!(:find_cart).and_return(mock_model(Cart).as_null_object)
      controller.set_checkout_in_progress(true)
      @target = {:controller => 'store', :action => 'checkout'}
      @controller.set_return_to @target
    end
    describe "when updating billing info" do
      before(:each) do
        params = {:id => @customer, :customer => {:street => "100 Embarcadero",   :zip => "94100",
            :email => "nobody@noplace.com"}}
        post :update, params
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
        flash[:notice].should match(/Contact information.*successfully updated/i)
      end
      it "should continue the checkout flow" do
        response.should redirect_to(@target)
      end
    end
  end

  describe "legacy routes" do
    it "should reroute the old /customers/login action" do
      get :login
      response.should redirect_to(login_path)
    end
    it "should route the old /customers/logout action" do
      get :logout
      response.should redirect_to(logout_path)
    end
  end
end

  
