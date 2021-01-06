require 'rails_helper'

describe ValidVouchersController, focus: true do
  describe 'adding redemptions' do
    before(:each) do
      login_as('boxoffice_manager')
      @show = create(:show)
    end
    it 'fails with message if no showdates exist' do
      get :new
      expect(response).to redirect_to(edit_show_path(@show))
      expect(flash[:alert]).to eq(t('season_setup.errors.no_performances_exist'))
    end
  end
end
