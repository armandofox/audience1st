require 'rails_helper'

describe ShowsController do
  before(:each) do ; login_as_boxoffice_manager ;  end
  describe '#index (Season tab)' do
    before(:each) do
      get :index
    end
    describe 'season menus range' do
      it 'defaults to current year if there are no shows' do
        year = Time.current.year
        expect(assigns(:earliest)).to eq year
        expect(assigns(:latest)).to eq year
      end
    end
  end
end

