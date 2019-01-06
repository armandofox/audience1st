require 'rails_helper'

describe 'customer search', :focus => true do
  before :all do
    @c = [
      ['Rachel', 'Ward', '123 Smith Lane', '94444'],
      ['Rachel', 'Smith', '44 Broadway', '94201'],
      ['Rachel', 'Wardman', '200 Main St', '94201'],
      ['Pat', 'Davis', '1 Davis St', '94201']
    ].map do |cust|
      create(:customer, :first_name => cust[0], :last_name => cust[1], :street => cust[2], :zip => cust[3])
    end
  end

  describe 'field matching' do
    [[ 0, %w(944), '94444']
    ].each do |testcase|
      record,terms,attr = testcase
      it "matches '#{terms}' with '#{attr}' for '#{@c[record]}'" do
        expect(@c[record].field_matching_terms(terms)).to eq(attr)
      end
    end
  end
  
  describe 'exact name matches' do
    [ %w(rachel)  =>  [0,1],
      %w(rachel ward) => [0],
      %w(ward rachel) => [0] ].each_with_index do |testcase,ndx|
      specify ndx do
        search = Customer.exact_name_matches(testcase[0])
        expected = testcase[1]
        expect(search.sort).to eq(expected.sort)
      end
    end
  end

end
