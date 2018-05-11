require 'rails_helper'

describe VouchertypesController do
  before(:each) do
    login_as_boxoffice_manager
    @vtype = create(:revenue_vouchertype)
  end
  describe "default season" do
    it "is remembered  after #index" do
      get :index, :season => '2019'
      get :index, :season => '2020'
      get :index
      expect(assigns(:season)).to eq(2020)
    end
    it "is used as default on new vouchertype" do
      get :index, :season => '2020'
      get :new
      expect(assigns(:vouchertype).season).to eq(2020)
    end
  end
  describe "creating" do
    it "should have current season by default" do
      old_season = Time.this_season
      Timecop.travel(2.years.from_now) do
        get :new
        expect(assigns(:vouchertype).season).to eq(old_season + 2)
      end
    end
  end
  describe "destroying" do
    it "should fail if vouchertype has any associated vouchers" do
      create(:revenue_voucher, :vouchertype => @vtype)
      delete :destroy, :id => @vtype.id
      response.should redirect_to vouchertypes_path(:season => @vtype.season)
      flash[:alert].should =~ /1 of them have already been issued/
    end
    it "should succeed if vouchertype has no associated vouchers or vouchertypes" do
      post :destroy, :id => @vtype.id
      Vouchertype.find_by_id(@vtype.id).should be_nil
      response.should redirect_to vouchertypes_path(:season => @vtype.season)
    end
  end

end

    
