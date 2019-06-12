require 'rails_helper'

describe ImportsController do
  before :each do
    #skip
    ImportsController.send(:public, :partial_for_import)
  end
  describe "creating new" do
    before :each do ; skip; @params = {:import => {:type => 'BrownPaperTicketsImport'}} ; end
    it "should simply redirect if import type is not given" do
      expect { post :create }.not_to raise_error
      expect(response).to redirect_to(new_import_path)
    end
    context "when new show name is given" do
      it "should create new show with valid name" do
        expect(Show).to receive(:create_placeholder!).with('New Show')
        post :create, {:new_show_name => 'New Show'}.merge(@params)
      end
      it "should create valid new show by making an invalid name valid" do
        old  = Show.count(:all)
        post :create, {:new_show_name => 'X'}.merge(@params)
        expect(Show.count(:all)).to eq(1+old)
        expect(Show.find(:first, :order => 'created_on DESC')).to be_valid
      end
      context "if new show name exactly matches existing show" do
        before :each do ; @existing = Show.create_placeholder!('Existing Show') ; end
        it "should not create a new show" do
          expect(Show).not_to receive(:create_placeholder!)
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
        end
        it "should display a warning message" do
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
          expect(flash[:alert]).to eq('Show "Existing Show" already exists.')
        end
        it "should redirect to new import" do
          post :create, {:new_show_name => 'Existing Show'}.merge(@params)
          expect(response).to redirect_to(:action => :new)
        end
      end
    end
    it "should not try to create a new show if no new show name is given" do
      @params[:show_id] = mock_model(Show).id.to_s
      expect(Show).not_to receive(:create_placeholder!)
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
      expect(@import).not_to be_completed
    end
    context "valid Customer data" do
      it "should use customer/customer_with_errors template for Customer import" do
        allow(@import).to receive(:class).and_return(CustomerImport)
        get :edit, :id => @import
        expect(assigns(:partial)).to eq('customers/customer_with_errors')
      end
      it "should use external_ticket_orders template for BPT import" do
        allow(@import).to receive(:class).and_return(BrownPaperTicketsImport)
        get :edit, :id => @import
        expect(assigns(:partial)).to eq('external_ticket_orders/external_ticket_order')
      end
    end
    context "for invalid data" do
      it "should display a message if no template for import class" do
        allow(controller).to receive(:partial_for_import).and_return nil
        get :edit, :id => @import
        expect(response).to redirect_to(:action => :new)
        expect(flash[:alert]).to match(/Don't know how to preview/)
      end
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
      expect(@import).to receive(:finalize).with(admin)
      put :update, :id => @import
    end
    it "should not get finalized if unsuccessful" do
      allow(@import).to receive(:errors).and_return(["An error"])
      expect(@import).not_to receive(:finalize)
      put :update, :id => @import
    end
  end
end
