require 'rails_helper'

describe CheckinsController do

  fixtures :customers

  before(:each) do
    login_as(:boxoffice_manager)
  end
    
  describe "showdate-dependent boxoffice action" do
    context 'with bad showdate' do
      before :each do
        @id = 999999
        @m = create(:showdate, :date => 1.day.from_now)
      end
      it 'should instead use current-or-next showdate if there is one' do
        Showdate.stub!(:current_or_next).and_return(@m)
        get :show, :id => @id
        assigns(:showdate).should == @m
      end
      it 'should use any existing showdate if no next showdate' 
      it 'should redirect to shows controller if no showdates at all' do
        Showdate.delete_all
        get :show, :id => @id
        response.should redirect_to(:controller => 'shows', :action => 'index')
      end
    end
    context 'with good showdate' do
      it "should work with valid showdate even if no others exist" do
        @m = create(:showdate, :date => 1.year.ago)
        get :show, :id => @m.id
        response.should render_template(:show)
      end
    end
  end

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
