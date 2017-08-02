require 'rails_helper'

describe 'info/availability.rxml' do
  before :each do
    assigns(:showdates,
      [sd = create(:showdate,
          :show => create(:show, :event_type => 'Special Event'),
          :thedate => 1.week.from_now)])
    create(:valid_voucher, :showdate => sd)
    render
  end
  it 'includes unescaped routes' do
    response.body.should_not match(/&amp/)
  end
  it 'does not include spurious newlines with URLs' do
    skip
    response.body.should_not match(/\nhttp:/)
  end
end

