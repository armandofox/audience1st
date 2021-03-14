require 'rails_helper'

describe ShowdatesController do
  before :each do
    login_as_boxoffice_manager
  end

  context 'test strong params' do
    before :each do
      @show = Show.create!(listing_date: 1.month.ago, season: Time.this_season, name: 'Dummy show')
      @mass_assignment_attack_params = {
        showdate_type: 'Ts',
        show_id: @show.id,
        showdate: {
          live_stream: '',
          stream_anytime: '1',
          description: '',
          max_advance_sales: 50000,
          show_id: @show.id,
          access_instructions: 'idk dude ruby is hard for me too',
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
      # dummy's to be filtered out
      @dummies = [:dummy_param_1, :dummy_param_2]
    end

    context 'validate strong params' do

      it 'checks strong params on create' do
        message = 'error caused if you have the attr_accessible to protect from mass assignment (deprecated rails 3)'
        expect{post :create, @mass_assignment_attack_params}.not_to raise_error ActiveModel::MassAssignmentSecurity::Error, message
        message = "new error will be raised if you delete attr_accessible and leave it unprotected (rails 4)"
        expect{post :create, @mass_assignment_attack_params}.not_to raise_error ActiveModel::ForbiddenAttributesError, message
        message = "ensure that the attribute hasn't been pushed to the model"
        post :create, @mass_assignment_attack_params
        last_showdate = Showdate.last
        @dummies.each { |symb| expect(last_showdate.attributes).not_to have_key(symb), message}
        message = 'ensure proper attribute is persisted'
        expect(last_showdate.max_advance_sales).to eq(50000), message
      end

      it 'checks strong params on update' do
        post :create, @mass_assignment_attack_params
        last_sdate = Showdate.last
        expect(last_sdate.max_advance_sales).to eq 50000

        # source features/season_setup/edit_showdate.feature:14
        update_params = {
          "showdate"=>{
            "thedate(1i)"=>"2010",
            "thedate(2i)"=>"5",
            "thedate(3i)"=>"1",
            "thedate(4i)"=>"20",
            "thedate(5i)"=>"00",
            "seatmap_id"=>"",
            "house_capacity"=>"200",
            "description"=>"Special performance",
            "max_advance_sales"=>"96"
          },
          "commit"=>"Save Changes",
          "controller"=>"showdates",
          "action"=>"update",
          "show_id"=>@show.id,
          "id"=>last_sdate.id
        }

        put :update, update_params
        # validate modification
        last_sdate = Showdate.last
        expect(last_sdate.max_advance_sales).to eq 96
        @dummies.each { |symbol| expect(last_sdate.attributes).not_to have_key(symbol) }
      end
    end

  end

end
