require 'rails_helper'

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
end
