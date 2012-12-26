require 'spec_helper'
include Utils

describe VouchertypesController do

  before(:each) do
    stub_globals_and_userlevel(:boxoffice_manager)
    @vtype = mock(Vouchertype, :name => 'Test Vouchertype', :season => '2012')
    Vouchertype.stub!(:find).and_return(@vtype)
  end
  
  describe "destroying a vouchertype" do
    it "should fail if logged-in user is not super-admin" do
      controller.stub!(:is_admin).and_return(false)
      post :destroy, :id => 1
      response.should redirect_to(:action => 'list', :season => '2012')
      flash[:notice].should =~ /superadmin/i
    end
    it "should fail if vouchertype has any associated vouchers" do
      controller.stub!(:is_admin).and_return(true)
      @vtype.stub_chain(:vouchers, :count).and_return(1)
      post :destroy, :id => 1
      response.should redirect_to(:action => 'list', :season => '2012')
      flash[:notice].should =~ /1 issued voucher/
    end
    it "should succeed if vouchertype has no associated vouchers or vouchertypes" do
      controller.stub!(:is_admin).and_return(true)
      @vtype.stub_chain(:vouchers, :count).and_return(0)
      @vtype.stub(:valid_vouchers).and_return([])
      @vtype.should_receive(:destroy)
      post :destroy, :id => 1
    end
  end

end

    
