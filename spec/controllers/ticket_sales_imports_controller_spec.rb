require 'rails_helper'
require 'csv'

describe TicketSalesImportsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe 'create ticket sales import' do
    it 'should redirect on a blank file' do
      response = post :create
      expect(response).to redirect_to(ticket_sales_imports_path)
      expect(flash[:alert]).to eq('Please choose a will-call list to upload.')
    end
  end

  describe 'safe params' do
    let(:mixed_params) {
      {
        'vendor' => 'TodayTix',
        'file' => Rack::Test::UploadedFile.new(Rails.root.join('spec/test_files/today_tix/two_valid_orders.csv'), 'application/csv'),
        'commit' => 'Upload',
        'controller' => 'ticket_sales_imports',
        'action' => 'create',
        'bad_param_one' => 'this does not matter',
        'bad_param_two' => 'trash'
      }
    }

    context 'when creating ticketsalesimport with a mix of permitted and unpermitted params' do
      before :each do
        post :create, mixed_params
        @post_tsi = TicketSalesImport.find(1)
      end
      it 'create will not set value of unpermitted param' do
        expect(response).to redirect_to(edit_ticket_sales_import_path id: 1)
        expect(@post_tsi).not_to have_attribute 'bad_param_one'
      end
      it 'create will set the value of permitted params' do
        expect(response).to redirect_to(edit_ticket_sales_import_path id: 1)
        expect(@post_tsi.vendor).to eq 'TodayTix'
      end
    end
  end
end
