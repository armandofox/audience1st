require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CustomersController do
  context "during checkout flow" do
    before(:each) do
      @customer = Customer.find_by_id(77)
      ApplicationController.stub!(:current_customer).and_return(@customer)
      ApplicationController.stub!(:current_admin).and_return(@customer)
      ApplicationController.stub!(:find_cart).and_return(mock_model(Cart).as_null_object)
      session[:checkout_in_progress] = true
    end
    it "should not cause the password to change when billing info updated" do
      controller.login_from_password(@customer)
      params = {:customer => {:street => "100 Embarcadero",   :zip => "94100",
          :email => "nobody@noplace.com"}}
      target = {:controller => 'store', :action => 'checkout'}
      session[:return_to] = target
      post :edit, params
      @customer.hashed_password_changed?.should be_false
      @customer.reload
      @customer.street.should == "100 Embarcadero"
      @customer.zip.should == "94100"
      response.should redirect_to(target)
      flash[:notice].should contain("Contact information was successfully updated")
    end

  end
end

  
