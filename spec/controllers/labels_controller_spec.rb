require "rails_helper"

describe LabelsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe "create label" do
    it "should create a new label from the controller"  do
      expect{ post :create, :label_name => "valid name" }.to change(Label, :count).by(+1)
      response = post :create, :label_name => "valid name"
      expect(response).to redirect_to( labels_path )
    end
  end

  describe "update label" do
    before :each do
      @lab = create(:label, :name => "valid name")
    end

    describe "create and update the label" do
      it 'should update the label properly' do
        expect(@lab.name).to eq("valid name")
        put :update, { :id => @lab.id, :label_name => "update name" }
        @lab.reload
        expect(@lab.name).to eq("update name")
      end
    end

    describe "bad update label" do
      it "should be a bad update due to a possible db issue" do
        #allow(@lab).to receive(:update_attributes).and_return(false)
        Label.any_instance.stub(:update_attributes).and_return(false)

        response = put :update, { :id => @lab.id, :label_name => "update name" }
        expect(@lab.name).to eq("valid name")
        expect(response).to redirect_to(labels_path)
      end

      it "bad update due to missing param" do
        expect {
          put :update, :id => @lab.id, :bad_param => "bad update call"
        }.to raise_error(ActionController::ParameterMissing)

        expect(flash[:alert]).to be_nil
        end
      end
  end
  
  describe "destroy label" do
    it "should create and destroy the label" do
      expect{ post :create, :label_name => "valid name" }.to change(Label, :count).by(+1)
      response = post :create, :label_name => "valid name"
      expect{ post :destroy, :id => 1 }.to change(Label, :count).by(-1)
    end
  end
  
  describe "index label" do
    before :each do
      @lab = create(:label, :name => "valid name")
    end

    it "should successfully get all labels" do
      response = get :index
      expect(response.status).to eq(200)
    end
  end
end
