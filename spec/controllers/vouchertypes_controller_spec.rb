require 'spec_helper'

describe VouchertypesController do
  fixtures :customers
  before(:each) do
    login_as customers(:boxoffice_manager)
    @vtype = create(:revenue_vouchertype)
  end
  
  describe "destroying a vouchertype" do
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

    
