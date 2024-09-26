require 'rails_helper'

describe LabelsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe "create label" do
    it "should create a new label from the controller" do
      expect { post :create, :params => {:label_name => "valid name"} }.to change(Label, :count).by(+1)
      response = post :create, :params => { :label_name => "valid name" }
      expect(response).to redirect_to(labels_path)
    end
    it "should not create a new label due to missing parameter" do
      expect {
        put :create, :params => {:bad_param => "bad update call"}
      }.to raise_error(ActionController::ParameterMissing)
    end
  end

  describe "update label" do
    before :each do
      @lab = create(:label, :name => "valid name")

    end
    describe "should create and update the label" do
      it 'should update the label properly' do
        expect(@lab.name).to eq("valid name")
        put :update, :params => { :id => @lab.id, :label_name => "update name" }
        @lab.reload
        expect(@lab.name).to eq("update name")
      end
    end
    describe "bad update label" do
      it "should be a bad update due to a possible db issue" do
        # Force an error with update_attributes for branch coverage
        allow_any_instance_of(Label).to receive(:update_attributes).and_return(false)

        response = put :update, :params => { :id => @lab.id, :label_name => "update name" }
        expect(@lab.name).to eq("valid name")
        expect(response).to redirect_to(labels_path)
        expect(@lab.errors).not_to be_nil
      end

      it "should be a bad update due to missing param" do
        expect {
          put :update, :params => {:id => @lab.id, :bad_param => "bad update call"}
        }.to raise_error(ActionController::ParameterMissing)
      end
      end
  end
  
  describe "destroy label" do
    it "should create and destroy the label" do
      expect{ post :create, :params => {:label_name => "valid name"} }.to change(Label, :count).by(+1)
      expect{ post :destroy, :params => {:id => Label.first.id} }.to change(Label, :count).by(-1)
    end
  end

  describe "index label" do
    before :each do
      @lab = create(:label, :name => "valid name")
    end
    it "should successfully get all labels via index" do
      response = get :index
      expect(response.status).to eq(200)
    end
  end

  describe "safe params" do
    let(:mixed_params) {
      {
        "label_name" => "my label name",
        "bad_param" => "garbo"
      }
    }

    context 'when creating label with a mix of permitted and unpermitted params' do
      before :each do
        post :create, :params => mixed_params
        @lab = Label.first
      end
      it "create will not set vaule of unpermitted params" do
        expect(@lab).not_to have_attribute 'bad_param'
      end
      it "create will set the value of permitted param" do
        expect(@lab.name).to eq("my label name")
      end
    end
  end
end
