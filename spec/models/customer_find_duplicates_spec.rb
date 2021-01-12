require 'rails_helper'

describe 'duplicates' do
  def near_dups?(a,b)
    a = a.split(/,/)
    b = b.split(/,/)
    c1 = create(:customer, :first_name => a[0], :last_name => a[1], :street => a[2], :created_by_admin => true)
    c2 = create(:customer, :first_name => b[0], :last_name => b[1], :street => b[2], :created_by_admin => true)
    res = Customer.find_suspected_duplicates
    res.size == 2 && res.include?(c1) && res.include?(c2)
  end
  before(:each) do
    create(:customer, :first_name => 'Crystal', :last_name => 'Zboncak', :street => '47148 Cole Rue')
    create(:customer, :first_name => 'Kieran', :last_name => 'Lehner', :street => '76515 Brenda Hill')
    create(:customer, :first_name => 'Mose', :last_name => 'Deckow', :street => '89221 Robb Flats')
    create(:customer, :first_name => 'Rodrigo', :last_name => 'Walker', :street => '7598 Ruecker Lane')
    create(:customer, :first_name => 'Gia', :last_name => 'Cruickshank', :street => '621 Rasheed Falls')
  end           
  context 'detected' do
    specify 'when both names match and 1 address is blank' do
      expect(near_dups?('John,Doe,3600 Broadway', 'John,Doe,')).to be_truthy
    end
    specify 'when both names match and address matches' do
      expect(near_dups?('John,Doe,3600 Broadway','John,Doe,3600 Broadway')).to be_truthy
    end
    specify 'when both names match and both addresses blank' do
      expect(near_dups?('John,Doe,','John,Doe,')).to be_truthy
    end
    specify 'when last name & first initial match, 1 address blank' do
      expect(near_dups?('John,Doe,','J,Doe,3600 Broadway')).to be_truthy
    end
    specify 'despite name capitalization' do
      expect(near_dups?('JOHN,DOE,','J,doe,3600 Broadway')).to be_truthy
    end
  end
  context 'not detected' do
    specify 'when both names match but address different' do
      expect(near_dups?('John,Doe,3600 Broadway','John,Doe,1 Main St')).to be_falsy
    end
  end
end


