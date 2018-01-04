require 'rails_helper'

describe CustomersController do
  describe "admin creating or updating valid customer" do
    before(:each) do
      @params = attributes_for(:customer)
      login_as_boxoffice_manager
      post :create, {:customer => @params}
    end
    it "should create the customer" do
      Customer.find_by_email(@params[:email]).should_not be_nil
    end
    it "should set created-by-admin flag" do
      Customer.find_by_email(@params[:email]).should be_created_by_admin
    end
    it "should not clear created-by-admin flag if admin updates record" do
      customer = Customer.find_by_email(@params[:email])
      put :update, {:id => customer, :customer => {:first_name => 'Bobby'}}
      customer.reload
      customer.should be_created_by_admin
    end
  end
  describe "user self-creation or self-update" do
    before(:each) do
      @params = attributes_for(:customer)
      login_as(nil)
      post :user_create, {:customer => @params, :password => "pass", :password_confirmation => "pass", :uid => @params[:email]}
    end
    it "should create the customer" do
      Customer.find_by_email(@params[:email]).should_not be_nil
    end
    it "should not set created-by-admin flag when created by customer" do
      Customer.find_by_email(@params[:email]).should_not be_created_by_admin
    end
  end
  describe "updating created-by-admin flag" do
    before(:each) do
      @customer = create(:customer)
      @customer.update_attribute(:created_by_admin, true)
      login_as @customer
    end
    it "should be cleared on successful update" do
      put :update, {:id => @customer, :customer => {:first_name => "Bobby"}}
      @customer.reload
      @customer.should_not be_created_by_admin
    end
    it "should update identity uid when updating email" do
      put :update, {:id => @customer, :customer => {:email => "new_email@gmail.com"}}
      @customer.reload
      expect(@customer.identity.uid).to eq("new_email@gmail.com")
    end
    it "should not be cleared if update fails" do
      put :update, {:id => @customer, :customer => {:first_name => ''}}
      @customer.reload
      @customer.should be_created_by_admin
    end
  end
  describe "checkout flow" do
    before(:each) do
      @customer = create(:customer)
      login_as @customer
      allow(controller).to receive(:find_cart).and_return(mock_model(Order).as_null_object)
      controller.set_checkout_in_progress(true)
      @target = {:controller => 'store', :action => 'checkout'}
      @controller.return_after_login @target
    end
    describe "when updating billing info" do
      before(:each) do
        params = {:id => @customer, :customer => {:street => "100 Embarcadero",   :zip => "94100",
            :email => "nobody@noplace.com"}}
        put :update, params
      end
      it "should update the address" do
        @customer.reload
        @customer.street.should == "100 Embarcadero"
        @customer.zip.should == "94100"
      end
      it "should display a message confirming the update" do
        flash[:notice].should match(/Contact information.*successfully updated/i)
      end
    end
  end

end

  
