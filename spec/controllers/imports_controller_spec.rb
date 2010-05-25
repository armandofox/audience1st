require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImportsController do
  describe "preview" do
    before(:each) do
      @import = mock("import", :null_object => true)
      Import.stub!(:find).and_return(@import)
    end
    context "valid Customer data" do
      it "should use customer/customer_with_errors template for Customer import" do
        @import.stub!(:preview).and_return([Customer.new])
        get :edit, :id => @import
        assigns[:partial].should == 'customers/customer_with_errors'
      end
    end
    context "for invalid data" do
      it "should display a message if no data to import" do
        @import.stub!(:preview).and_return []
        get :edit, :id => @import
        response.should redirect_to(:action => :new)
        flash[:warning].should match(/Couldn't find any valid data to import/)
      end
      it "should display a message if no template for import class" do
        @import.stub!(:preview).and_return([Option.new])
        get :edit, :id => @import
        response.should redirect_to(:action => :new)
        flash[:warning].should match(/Don't know how to preview/)
      end
    end
  end


end
