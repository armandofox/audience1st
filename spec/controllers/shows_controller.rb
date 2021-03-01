require 'rails_helper'

describe ShowsController do

  before(:each) do
    login_as_boxoffice_manager
  end

  describe "index" do
    it "should assign season" do
      allow(Show).to receive(:minimum).and_return(2000)
      allow(Show).to receive(:maximum).and_return(2010)
      get :index, :season => 2010
      expect(assigns(@season)[:season]).to eq(2010)
    end

  end
  describe "destroy show" do
    before :each do
      @s = create(:show, :name => "valid name")
    end


    it "should create a new label from the controller"  do
      ##@mock_s = mock_model("Show")
      #allow(Show).to receive(:permit).and_return(@mock_s)
      #expect{ post :create, :show => @mock_s }.to change(Show, :count).by(+1)
      #response = post :create,  :show => mock_model("Show")
      expect{ post :destroy, :id => 1 }.to change(Show, :count).by(-1)
    end
  end
end
