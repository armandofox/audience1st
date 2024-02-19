require 'rails_helper'

DIR = File.join(Rails.root, 'spec', 'test_files', 'seatmaps')

describe SeatmapsController do
  before(:each) do ; login_as_boxoffice_manager ; end
  it 'parses uploaded ASCII CSV' do
    file = fixture_file_upload File.join(DIR, 'valid_seatmap.csv')
    params = {:name => 'x', :csv => file}
    post :create, :params => params
    expect(response).to be_redirect
  end
  it 'does not choke on UTF-8 CSV' do
    file = fixture_file_upload File.join(DIR, 'utf8_only_seatmap.csv')
    params = {:name => 'x', :csv => file}
    expect { post :create, :params => params }.not_to raise_error
  end
  it 'does not raise exception if CSV left blank' do
    expect { post :create, :params => {:name => 'x'} }.not_to raise_error
  end
end
