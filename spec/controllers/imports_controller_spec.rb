require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImportsController do
  before :each do
    ImportsController.send(:public, :partial_for_import)
  end
  describe "creating new" do
    before :each do ; @params = {:import => {:type => 'BrownPaperTicketsImport'}} ; end
    it "should simply redirect if import type is not given" do
      lambda { post :create }.should_not raise_error
      response.should redirect_to(new_import_path)
    end
    context "when new show name is given" do
      it "should create new show with valid name" do
        Show.should_receive(:create_placeholder!).with('New Show')
        post :create, {:new_show_name => 'New Show'}.merge(@params)
      end
      it "should create valid new show by making an invalid name valid" do
        old  = Show.count(:all)
        post :create, {:new_show_name => 'X'}.merge(@params)
        Show.count(:all).should == 1+old
        Show.find(:first, :order => 'created_on DESC').should be_valid
      end
      context "if new show name exactly matches existing show" do
        before :all do ; @existing = Show.create_placeholder!('Existing Show') ; end
        it "should not create a new show" do
          Show.should_not_receive(:create_placeholder!)
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
        end
        it "should display a warning message" do
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
          flash[:warning].should == 'Show "Existing Show" already exists.'
        end
        it "should redirect to new import" do
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
          response.should redirect_to(:action => :new)
        end
      end
    end
    it "should not try to create a new show if no new show name is given" do
      @params[:show_id] = mock_model(Show).id.to_s
      Show.should_not_receive(:create_placeholder!)
      post :create, @params
    end        
  end
  describe "preview" do
    before(:each) do
      @import = TicketSalesImport.new
      Import.stub!(:find).and_return(@import)
    end
    it "should not mark import as completed" do
      get :edit, :id => @import
      @import.should_not be_completed
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
  describe "import" do
    before(:each) do
      @import = TicketSalesImport.new
      @import.stub(:import!).and_return([[:a,:b],[:c]])
      Import.stub(:find).and_return(@import)
    end
    it "should get finalized if successful" do
      controller.stub(:logged_in).and_return(mock_model(Customer).id)
      @import.should_receive(:finalize)
      put :update, :id => @import
    end
    it "should not get finalized if unsuccessful" do
      @import.stub(:errors).and_return(["An error"])
      @import.should_not_receive(:finalize)
      put :update, :id => @import
    end
  end
end
