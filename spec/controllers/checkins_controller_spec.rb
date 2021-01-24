require 'rails_helper'

describe CheckinsController do

  before(:each) do
    login_as_boxoffice_manager
  end
    
  describe "showdate-dependent boxoffice action" do
    context 'with bad showdate' do
      before :each do
        @id = 999999
        @m = create(:showdate, :date => 1.day.from_now)
      end
      it 'should instead use current-or-next showdate if there is one' do
        allow(Showdate).to receive(:current_or_next).and_return(@m)
        get :show, :id => @id
        expect(assigns(:showdate)).to eq(@m)
      end
      it 'should redirect to shows controller if no showdates at all' do
        Showdate.delete_all
        get :show, :id => @id
        expect(response).to redirect_to(:controller => 'shows', :action => 'index')
      end
    end
    context 'with good showdate' do
      it "should work with valid showdate even if no others exist" do
        show = create(:show, :season => 2009)
        @m = create(:showdate, :date => 1.year.ago, :show => show)
        get :show, :id => @m.id
        expect(response).to render_template(:show)
      end
    end
  end

  describe "walkup sale" do
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

end
