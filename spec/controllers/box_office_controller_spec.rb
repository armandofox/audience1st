require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Utils

describe BoxOfficeController do

  before(:each) do
    stub_globals_and_userlevel(:boxoffice, :boxoffice_manager)
  end
    
  describe "visiting boxoffice page with bad showdate", :shared => true do
    context "when there is an upcoming show" do
      before(:all) do
        Showdate.stub!(:current_or_next).and_return(@m = mock_model(Showdate))
      end
      it "should redirect to next show" do
        get :walkup, :id => @id
        response.should redirect_to(:action => 'walkup', :id => @m)
      end
    end
    context "when there is no next show" do
      before(:all) do
        Showdate.stub!(:current_or_next).and_return(nil)
      end
      it "should redirect to any show" do
        Showdate.stub!(:find).and_return(@m = mock_model(Showdate))
        get :walkup, :id => @id
        response.should redirect_to(:action => 'walkup', :id => @m)
      end
    end
    context "when there are no shows at all" do
      it "should redirect to shows page with a message" do
        Showdate.stub!(:find).and_return(nil)
        get :walkup, :id => @id
        response.should redirect_to(:controller => 'shows', :action => 'index')
      end
    end
  end

  describe "visiting boxoffice page with no showdate" do
    @id = nil
    it_should_behave_like "visiting boxoffice page with bad showdate"
  end
  describe "visiting boxoffice page with nonexistent showdate" do
    @id = 999999
    Showdate.find_by_id(@id).should == nil
    it_should_behave_like "visiting boxoffice page with bad showdate"
  end

  describe "transferring already-sold walkup vouchers" do
    context "no transfer occurs", :shared => true do
      it "should not attempt to transfer" do
        Voucher.should_not_receive(:destroy_multiple)
        Voucher.should_not_receive(:transfer_multiple)
        post :modify_walkup_vouchers, @params
      end
      it "should redirect" do
        post :modify_walkup_vouchers, @params
        response.should redirect_to(:action => :index)
      end
    end
    context "when no vouchers are checked" do
      before(:each) do ;  @params = {} ; end
      it_should_behave_like "no transfer occurs"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/you didn't select any vouchers/i)
      end
    end
    context "when at least one voucher is not found" do
      before(:each) do
        found_voucher_id = Voucher.create!.id
        not_found_id = found_voucher_id + 1
        @params = {:vouchers => [found_voucher_id, not_found_id] }
      end
      it_should_behave_like "no transfer occurs"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/no changes were made/i)
      end
    end
    context "when neither Transfer nor Destroy is pressed" do
      before(:each) do
        @params = {:vouchers => [Voucher.create!.id], :commit => 'nothing'}
      end
      it_should_behave_like "no transfer occurs"
      it "should display appropriate error" do
        post :modify_walkup_vouchers, @params
        flash[:warning].should match(/unrecognized action/i)
      end
    end
    context "when target showdate is not found"
    context "when all checked vouchers exist"
  end

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
