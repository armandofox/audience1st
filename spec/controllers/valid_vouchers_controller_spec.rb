require 'rails_helper'

describe ValidVouchersController do
  describe 'adding redemptions' do
    before(:each) do
      login_as_boxoffice_manager
      @show = create(:show)
    end
    it 'fails with message if no showdates exist' do
      get :new, :show_id => @show.id
      expect(response).to redirect_to(edit_show_path(@show))
      expect(flash[:alert]).to eq(t('season_setup.errors.no_performances_exist'))
    end
    it 'fails with message if no vouchertypes exist' do
      create(:showdate, :show => @show)
      get :new, :show_id => @show.id
      expect(response).to redirect_to(edit_show_path(@show))
      expect(flash[:alert]).to eq(t('season_setup.errors.no_redemptions_without_vouchertypes', :season => '2010'))
    end
  end
end
