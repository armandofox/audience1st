require 'rails_helper'

describe 'duplicates' do
  context 'detected' do
    specify 'when both names match and 1 address is blank' do
      expect('John,Doe,3600 Broadway::John,Doe,').to be_near_dups
    end
    specify 'when both names match and address matches' do
      expect('John,Doe,3600 Broadway::John,Doe,3600 Broadway').to be_near_dups
    end
    specify 'when both names match and both addresses blank' do
      expect('John,Doe,::John,Doe,').to be_near_dups
    end
    specify 'when last name & first initial match, 1 address blank' do
      expect('John,Doe,::J,Doe,3600 Broadway').to be_near_dups
    end
    specify 'despite name capitalization' do
      expect('JOHN,DOE,::J,doe,3600 Broadway').to be_near_dups
    end
  end
  context 'not detected' do
    specify 'when both names match but address different' do
      expect('John,Doe,3600 Broadway::John,Doe,1 Main St').not_to be_near_dups
    end
  end
end


