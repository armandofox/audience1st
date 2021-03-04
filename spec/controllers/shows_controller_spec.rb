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
      expect{ post :destroy, :id => 1 }.to change(Show, :count).by(-1)
    end
  end

  describe "safe params" do
    let(:mixed_params) {
      {
        show: {
          name: "some show",
          description: "desc",
          bad_param: "bad",
          listing_date: Date.today
        }
      }
    }
    let(:mixed_update_params) {
      { 
          name: "updated",
          bad_param: "bad"
      }
    }

    context "when creating show with a mix of permitted and unpermitted params" do 
      before :each do 
        post :create, mixed_params
      end
      it "create will not set value of unpermitted param" do
        expect(response).to redirect_to(edit_show_path( id:1 ))
        
        @post_show = Show.find(1)
        expect { @post_show.bad_parmam }.to raise_error(NoMethodError)
      end
      it "create will set the value of permitted params" do
        expect(response).to redirect_to(edit_show_path( id:1 ))
        
        @post_show = Show.find(1)
        expect( @post_show.name ).to eq("some show")
        expect( @post_show.description ).to eq("desc")
        expect( @post_show.listing_date ).to eq(Date.today)
      end
    end

    context "when updating with a mix of permitted and unpermitted params" do
      before :each do
        post :create, mixed_params
      end
      it "should update the name" do
        @s = Show.find(1)
        response = post :update, :id => @s.id, :show => mixed_update_params
        expect(response).to redirect_to edit_show_path(@s)
        
        @s.reload
        expect( @s.name).to eq("updated")
      end
    end
  end

  describe "update show" do
    it "should update the description" do
      @s = create(:show, :name => "valid name")
      expect(@s.description).to be_nil
      response = post :update, :id => @s.id, :show => { :description => "updated description" }
      expect(response).to redirect_to edit_show_path(@s)

      @s.reload
      expect(@s.description).to eq("updated description")
    end
  end
end
