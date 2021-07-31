require 'rails_helper'

describe SeatingZone do
  describe 'invalid shortname' do
    ['New:one', 'new-one', 'TooLongName', 'sh!r?t', ''].each do |s|
      specify s do
        expect(SeatingZone.new(:name => 'SeatingZone', :short_name => s)).not_to be_valid
      end
    end
  end
  specify 'valid shortname' do
    expect(SeatingZone.new(:name => 'SeatingZone', :short_name => 'short')).to be_valid
  end
  describe 'invalid display name' do
    ['New:one', 'New - one'].each do |s|
      specify s do
        expect(SeatingZone.new(:name => s, :short_name => 's')).not_to be_valid
      end
    end
  end
  specify 'valid with valid names' do
    expect(SeatingZone.new(:name => 'GeneralReserved', :short_name => 'r')).to be_valid
  end
end

