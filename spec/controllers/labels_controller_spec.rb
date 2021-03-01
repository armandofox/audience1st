require 'rails_helper'

describe LabelsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe "showdate-dependent boxoffice action" do
    context 'with bad showdate' do
      # before :each do
      #   @l = create(:showdate, :name => "Test Label")
      # end
      let(:valid_params) do
        { label_name: 'Test Label' }
      end

      let(:new_params) do
        { label_name: 'Updated Label' }
      end

        it 'should create a new label from the controller' do
          expect{ post :create, valid_params }.to change(Label, :count).by(+1)
          expect(response).to redirect_to(:controller => 'shows', :action => 'index')
        end

        it 'should not create a new label from the controller' do
          invalid_params = {
            label_
          }
          expect{ post :create, valid_params }.to change(Label, :count).by(+1)
        end

        it 'should create and update the label' do
          expect{ post :create, valid_params }.to change(Label, :count).by(+1)
          expect{ post :update, new_params }.to change(Label, :count).by(+1)
        end
    end
  end
end
