require 'rails_helper'

describe 'info/availability.rss.builder', :type => :view do
  before :each do
    assign(:showdates,
      [sd = create(:showdate,
          :show => create(:show, :event_type => 'Special Event'),
          :thedate => 1.week.from_now)])
    create(:valid_voucher, :showdate => sd)
    render
  end
  it 'includes unescaped routes' do
    expect(response.body).not_to match(/&amp/)
  end
  it 'does not include spurious newlines with URLs' do
    expect(response.body).not_to match(/\nhttp:/)
  end
end

