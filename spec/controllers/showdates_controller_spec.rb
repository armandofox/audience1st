require 'rails_helper'

describe ShowdatesController do
  before :each do
    login_as_boxoffice_manager
  end

  context 'test strong params' do
    before :each do
      puts Time.current
      show = Show.create!(listing_date: 1.month.ago, season: Time.this_season, name: 'Dummy show')
      @mass_assignment_attack_params = {
        showdate_type: 'Ts',
        show_id: show.id,
        showdate: {
          live_stream: '',
          stream_anytime: '1',
          description: '',
          house_capacity: 0,
          max_advance_sales: 50000,
          show_id: show.id,
          # these are 2 disallowed params that should cause an error
          dummy_param_1: 'trying to sneak past',
          dummy_param_2: 'sneaky uWu'
        },
        saved_max_sales: '',
        day: [0],
        time: {year: 2010, month: 1, day: 1, hour: 20, minute: 00},
        show_run_dates: {start: '"2010-01-01"', end: '"2010-01-03"'},
        stream_until: {year: 2010, month: 1, day: 1, hour: 23, minute: 45},
      }


    end
    it 'checks strong params' do
      # this is the error caused if you have the attr_accessible to protect from mass assignment (deprecated rails 3)
      expect{post :create, @mass_assignment_attack_params}.not_to raise_error ActiveModel::MassAssignmentSecurity::Error
      # this is the new error to be raised when protecting with .permit from mass assignment (rails 4)
      expect{post :create, @mass_assignment_attack_params}.to raise_error ActiveModel::ForbiddenAttributesError
    end
  end

end