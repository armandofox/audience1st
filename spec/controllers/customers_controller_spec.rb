require 'rails_helper'

describe CustomersController do
  describe "admin creating or updating valid customer" do
    before(:each) do
      @params = attributes_for(:customer)
      login_as_boxoffice_manager
      post :create, {:customer => @params}
    end
    it "should create the customer" do
      expect(Customer.find_by_email(@params[:email])).not_to be_nil
    end
    it "should set created-by-admin flag" do
      expect(Customer.find_by_email(@params[:email])).to be_created_by_admin
    end
    it "should not clear created-by-admin flag if admin updates record" do
      customer = Customer.find_by_email(@params[:email])
      put :update, {:id => customer, :customer => {:first_name => 'Bobby'}}
      customer.reload
      expect(customer).to be_created_by_admin
    end
  end
  describe "user self-creation or self-update" do
    before(:each) do
      @params = attributes_for(:customer)
      login_as(nil)
      post :user_create, {:customer => @params}
    end
    it "should create the customer" do
      expect(Customer.find_by_email(@params[:email])).not_to be_nil
    end
    it "should not set created-by-admin flag when created by customer" do
      expect(Customer.find_by_email(@params[:email])).not_to be_created_by_admin
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
      expect(@customer).not_to be_created_by_admin
    end
    it "should not be cleared if update fails" do
      put :update, {:id => @customer, :customer => {:first_name => ''}}
      @customer.reload
      expect(@customer).to be_created_by_admin
    end
  end
  describe "checkout flow" do
    before(:each) do
      @customer = create(:customer)
      login_as @customer
      fake_order = mock_model(Order).as_null_object
      allow(controller).to receive(:find_cart).and_return(fake_order)
      controller.set_order_in_progress(fake_order)
      @target = {:controller => 'store', :action => 'checkout'}
      @controller.return_after_login @target
    end
    describe "when updating billing info" do
      before(:each) do
        params = {:id => @customer, :customer => {:street => "100 Embarcadero",   :zip => "94100",
            :email => "nobody@noplace.com"}}
        put :update, params
      end
      it "should not update the password" do
        expect(@customer.crypted_password_changed?).to be_falsey
      end
      it "should update the address" do
        @customer.reload
        expect(@customer.street).to eq("100 Embarcadero")
        expect(@customer.zip).to eq("94100")
      end
      it "should display a message confirming the update" do
        expect(flash[:notice]).to match(/Contact information.*successfully updated/i)
      end
    end
  end

end

  
