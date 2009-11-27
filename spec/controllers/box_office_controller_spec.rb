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

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
