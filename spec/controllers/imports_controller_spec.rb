require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImportsController do
  describe "preview" do
    it "should use customer/customer template for Customer import" do
      @import = mock_model(CustomerImport, :preview => [[], Customer])
      Import.stub!(:find).and_return(@import)
      get :edit, :id => @import
      assigns[:partial].should == 'customer/customer'
    end
    it "should display a message if import type not found" do
      @import = mock_model(Import, :preview => [[], 'Foobar'])
      Import.stub!(:find).and_return(@import)
      get :edit, :id => @import
      response.should redirect_to(:action => :new)
      flash[:warning].should == "Don't know how to preview a collection of Foobars."
    end
  end


end
