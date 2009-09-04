require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VouchertypesController do

  before(:each) do
    controller.stub!(:set_globals).and_return(true)
    controller.stub!(:is_boxoffice_manager_filter).and_return(true)
    controller.stub!(:logged_in_id).and_return(1)
    @vtype = mock(Vouchertype, :name => 'Test Vouchertype')
    Vouchertype.stub!(:find).and_return(@vtype)
  end
  
  describe "destroying a vouchertype" do
    it "should fail if logged-in user is not super-admin" do
      controller.stub!(:is_admin).and_return(false)
      post :destroy, :id => 1
      response.should redirect_to(:action => 'list')
      flash[:notice].should =~ /superadmin/i
    end
    it "should fail if vouchertype has any associated vouchers" do
      controller.stub!(:is_admin).and_return(true)
      @vtype.stub_chain(:vouchers, :count).and_return(1)
      post :destroy, :id => 1
      response.should redirect_to(:action => 'list')
      flash[:notice].should =~ /1 issued voucher/
    end
    it "should succeed if vouchertype has no associated vouchers" do
      controller.stub!(:is_admin).and_return(true)
      @vtype.stub_chain(:vouchers, :count).and_return(0)
      @vtype.should_receive(:destroy)
      post :destroy, :id => 1
    end
  end

end

    
