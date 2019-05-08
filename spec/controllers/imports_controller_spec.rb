require 'rails_helper'

describe ImportsController do
  before :each do
    #skip
    ImportsController.send(:public, :partial_for_import)
  end
  describe "creating new" do
    before :each do ; skip; @params = {:import => {:type => 'BrownPaperTicketsImport'}} ; end
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
        before :each do ; @existing = Show.create_placeholder!('Existing Show') ; end
        it "should not create a new show" do
          Show.should_not_receive(:create_placeholder!)
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
        end
        it "should display a warning message" do
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
          flash[:alert].should == 'Show "Existing Show" already exists.'
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
      skip
      @import = TicketSalesImport.new
      allow(Import).to receive(:find).and_return(@import)
    end
    it "should not mark import as completed" do
      get :edit, :id => @import
      @import.should_not be_completed
    end
    context "valid Customer data" do
      it "should use customer/customer_with_errors template for Customer import" do
        allow(@import).to receive(:class).and_return(CustomerImport)
        get :edit, :id => @import
        assigns(:partial).should == 'customers/customer_with_errors'
      end
      it "should use external_ticket_orders template for BPT import" do
        allow(@import).to receive(:class).and_return(BrownPaperTicketsImport)
        get :edit, :id => @import
        assigns(:partial).should == 'external_ticket_orders/external_ticket_order'
      end
    end
    context "for invalid data" do
      it "should display a message if no template for import class" do
        allow(controller).to receive(:partial_for_import).and_return nil
        get :edit, :id => @import
        response.should redirect_to(:action => :new)
        flash[:alert].should match(/Don't know how to preview/)
      end
    end
  end
  describe "invalid TodayTix CSV file" do
    before(:each) do
      @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("spec/import_test_files/todaytix/all_in_one.csv"))
      @parser = TicketSalesImportParser::TodayTix.new(@import)
    end
    it "should raise error if file is blank" do
      @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("spec/import_test_files/todaytix/empty.csv"))
      @parser = TicketSalesImportParser::TodayTix.new(@import)
      res = @parser.valid?
      @import.errors[:vendor].should include("Data is invalid because file is empty")
      res.should be_falsy
    end
    it "should raise error if headers is missing critical columns" do
      @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("spec/import_test_files/todaytix/invalid_header.csv"))
      @parser = TicketSalesImportParser::TodayTix.new(@import)
      res = @parser.valid?
      @import.errors[:vendor].should include("Data is invalid because header is missing required columns")
      res.should be_falsy
    end
    it "should raise error if row data has blank order number (not missing)" do
      res = @parser.valid?
      @import.errors[:vendor].should include("Data is invalid because Order num can't be blank on row 2")
      res.should be_falsy
    end
    it "should raise error if row data has invalid email" do
      res = @parser.valid?
      @import.errors[:vendor].should include("Data is invalid because Email is invalid on row 3") 
      res.should be_falsy
    end
    it "should raise error if row data has invalid performance date" do
      res = @parser.valid?
      @import.errors[:vendor].should include("Data is invalid because Performance date is an invalid datetime on row 4") 
      res.should be_falsy
    end
  end
  
  describe "valid TodayTix CSV file" do
    before(:each) do
      @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("spec/import_test_files/todaytix/valid.csv"))
      @parser = TicketSalesImportParser::TodayTix.new(@import)
    end
    it "should return true if all rows are valid" do
      res = @parser.valid?
      res.should be_truthy
    end
  end
  
  describe "import" do
    before(:each) do
      skip
      @import = TicketSalesImport.new
      allow(@import).to receive(:import!).and_return([[:a,:b],[:c]])
      allow(Import).to receive(:find).and_return(@import)
    end
    it "should get finalized if successful" do
      admin = create(:customer, :role => :boxoffice)
      allow(controller).to receive(:logged_in_user).and_return(admin)
      @import.should_receive(:finalize).with(admin)
      put :update, :id => @import
    end
    it "should not get finalized if unsuccessful" do
      allow(@import).to receive(:errors).and_return(["An error"])
      @import.should_not_receive(:finalize)
      put :update, :id => @import
    end
  end
end
