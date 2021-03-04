require 'rails_helper'
require 'csv'

describe TicketSalesImportsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe "create ticket sales import" do
    it "should redirect on a blank file"  do
      response = post :create
      expect(response).to redirect_to( ticket_sales_imports_path )
      expect(flash[:alert]).to eq("Please choose a will-call list to upload.")
    end
  end

  describe "safe params" do
    let(:csv_tsi_file)  { 
      {
      file: fixture_file_upload(__dir__ + "/ticket_sales_imports_file.csv", "application/csv")
      #instance_double(Rack::Test::UploadedFile, content_type: "application/csv", original_filename: "blank.csv", file_name: "ticket-sales-import-fn.cs")
      }
    }

    let(:mixed_params) {
      {
        vendor: {
          name: "TodayTix",
        },
        file: csv_tsi_file[:file],#File.open(__dir__ + "/ticket_sales_imports_file.csv", "r"),# double("file", :read => "some string", :original_filename => "og_fn.csv"),
        bad_param: "bad"
      }
    }
    

    context "when creating ticketsalesimport with a mix of permitted and unpermitted params" do 
      before :each do
        puts Dir.pwd
        @mixed_params = { vendor: { name: "TodayTix"}, file: csv_tsi_file[:file],}
        #allow(ActionDispatch::Http::UploadedFile).to receive(:read).and_return("some string")
        #puts mixed_params[:file].read
        post :create, mixed_params
      end
      it "create will not set value of unpermitted param" do
        expect(response).to redirect_to(edit_ticket_sales_import_path( id:1 ))
        
        @post_tsi = TicketSalesImport.find(1)
        expect { @post_tsi.bad_parmam }.to raise_error(NoMethodError)
      end
      it "create will set the value of permitted params" do
        expect(response).to redirect_to(edit_ticket_sales_import_path( id:1 ))
        
        @post_tsi = TicketSalesImport.find(1)
        expect( @post_tsi.vendor.name ).to eq("some vendor")
        expect( @post_tsi.file ).not_to be_nil
        #expect( @post_tsi.listing_date ).to eq(Date.today)
      end
    end
  end
end
