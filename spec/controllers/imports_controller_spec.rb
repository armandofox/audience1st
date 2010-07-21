require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImportsController do
  before :each do
    ImportsController.send(:public, :partial_for_import)
  end
  describe "preview" do
    before(:each) do
      @import = mock("import", :null_object => true)
      Import.stub!(:find).and_return(@import)
    end
    context "valid Customer data" do
      it "should use customer/customer_with_errors template for Customer import" do
        @import.stub!(:class).and_return(CustomerImport)
        get :edit, :id => @import
        assigns[:partial].should == 'customers/customer_with_errors'
      end
      it "should use external_ticket_orders template for BPT import" do
        @import.stub!(:class).and_return(BrownPaperTicketsImport)
        get :edit, :id => @import
        assigns[:partial].should == 'external_ticket_orders/external_ticket_order'
      end
    end
    context "for invalid data" do
      it "should display a message if no template for import class" do
        controller.stub!(:partial_for_import).and_return nil
        get :edit, :id => @import
        response.should redirect_to(:action => :new)
        flash[:warning].should match(/Don't know how to preview/)
      end
    end
  end


end
