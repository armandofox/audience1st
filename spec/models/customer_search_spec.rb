require 'rails_helper'

describe 'quick donation customer search' do
  context 'when matching customer' do
    specify 'has different address, address gets updated' do
      create(:customer, :email => 'joe@joescafe.com')
      @new = Customer.for_donation({:street => '999 Broadway', :email => 'joe@joescafe.com'})
      expect(@new.street).to eq('999 Broadway')
    end
    specify 'has blank address, address gets updated' do
      create(:customer, :street => nil, :city => nil, :state => nil, :zip => nil, :created_by_admin => true)
      @new = Customer.for_donation({:email => 'joe@joescafe.com',
                                    :street => '999 Broadway', :city => 'New York',
                                    :state => 'NY', :zip => '10019'})
      expect(@new.street).to eq '999 Broadway'
      expect(@new.city).to eq 'New York'
      expect(@new.state).to eq 'NY'
      expect(@new.zip).to eq '10019'
    end
    describe 'when no email match' do
      before(:each) do
        @cust = create(:customer, :first_name => 'Joe', :last_name => 'Mallon',
                      :street => '999 Broadway', :city => 'New York',
                      :state => 'NY', :zip => '10019', :email => 'tom@fool.com')
      end
      specify 'but unique address match, returns customer using same address' do
        @new = Customer.for_donation({:first_name => 'joe', :last_name => 'mallon',
                                      :street => '999 Broadway', :city => 'New York',
                                      :state => 'NY', :zip => '10019'})
        expect(@new).to eq(@cust)
      end
      specify 'and no unique address match, creates customer with given address' do
        @new = Customer.for_donation({:first_name => 'joe', :last_name => 'mallon',
                                      :street => '123 Fakeroo', :city => 'Albany',
                                      :state => 'CA', :zip => '94745'})
        expect(@new.street).to eq('123 Fakeroo')
        expect(@new.city).to eq('Albany')
        expect(@new.state).to eq('CA')
        expect(@new.zip).to eq('94745')
      end
    end
  end
end

describe 'possible customer matches' do
  before :each do
    @c = [
      create(:customer, :first_name => 'Chris', :last_name => 'Jones', :email => 'cjones@mail.com'),
      create(:customer, :first_name => 'Christopher', :last_name => 'Jones', :email => '', :created_by_admin => true),
      create(:customer, :first_name => 'Barb', :last_name => 'Jones', :email => 'bjones@mail.com'),
      create(:customer, :first_name => 'C', :last_name => 'Jones', :email => '', :created_by_admin => true)
    ]
  end
  it "(even if name does not match)" do
    match = Customer.possible_matches('Chris','Jones','bjones@mail.com')
    expect(match).to include(@c[2])
  end
  it "includes both exact-email match and unique name match, but not nonmatching email" do
    match = Customer.possible_matches('Chris','Jones','bjones@mail.com')
    expect(match).to include(@c[2]) # exact match on email
    expect(match).to include(@c[1]) # near match on name w/o email
    expect(match).to include(@c[3]) # initial match w/o email
  end
  it "includes non-unique first name matches when no email" do
    match = Customer.possible_matches('C','Jones')
    expect(match).to include(@c[0]) # non-exact match on first name w/o email
    expect(match).to include(@c[1]) # non-exact match on first name w/o email
    expect(match).to include(@c[3]) # non-exact match on first name w/o email
    expect(match).not_to include(@c[2]) # non-exact match on first name w/o email
  end
  it "returns empty list when no matches" do
    expect(Customer.possible_matches('Shirley','Jones')).to be_empty
  end
end

describe 'customer search' do

  before :each do
    @c = [
      ['Sandy', "O'Shea", '123 Smith Lane', '94444'],
      ['Sandy', 'Smith', '44 Broadway', '94201'],
      ['Sandy', "O'Sheamus", '100 Main St', '94201'],
      ['Anne', 'Frank', '100 Main St', '99999'],
      ['Frank', 'Anne', '99 Main St', '99999'],
    ].map do |cust|
      create(:customer, :first_name => cust[0], :last_name => cust[1], :street => cust[2], :zip => cust[3])
    end
    @ids = @c.map(&:id)
  end

  describe 'field matching' do
    specify '1' do ; expect(@c[0].field_matching_terms %w(944)).to eq('94444') ; end
    specify '2' do ; expect(@c[0].field_matching_terms %w(235 war)).to eq('') ; end
    specify '3' do ; expect(@c[0].field_matching_terms %w(lane ward)).to eq('123 Smith Lane') ; end
  end

  describe 'non-name field matches' do
    [ [%w(main),        [2,3,4]],
      [%w(100 main),     [2,3]],
      [%w(100),         [2,3]],
      [%w(smith),       [0]],
      [%w(94 main),     [2]],
      [%w(100 9),       [2,3]],
      [%w(xxx),         []],
      [%w(main xxx),    []]
    ].each do |testcase|
      specify "for #{testcase[0]}" do
        search = Customer.other_term_matches(testcase[0]).to_a.map { |c| @c.index(c) }
        expected = testcase[1]
        expect(search.sort).to eq(expected.sort)
      end
    end
  end
  
  describe 'matching names' do
    describe 'exactly' do
      [ [%w(sandy),         [0,1,2]],
        [%w(sandy o'shea), [0]],  # '
        [%w(o'),           []],
        [%w(o'shea sandy), [0]],
        [%w(anne frank),    [3,4]],
        [%w(frank anne),    [3,4]],
        [%w(sandy frank),  []],
        [%w(frank anne sandy), []]
      ].each_with_index do |testcase,ndx|
        specify "for #{testcase[0]}" do
          search = Customer.exact_name_matches(testcase[0]).to_a.map { |c| @c.index(c) }
          expected = testcase[1]
          expect(search.sort).to eq(expected.sort)
        end
      end
    end

    describe 'partially' do
      [ [%w(sandy),        [0,1,2]],
        [%w(sandy o'shea), [0,2]],
        [%w(o'shea sandy), [0,2]],
        [%w(ann frank),     [3,4]],
        [%w(fran anne),     [3,4]],
        [%w(san xxx),      []],
        [%w(xxx),           []],
        [%w(xxx yyy),       []],
        [%w(an),            [0,1,2,3,4]]
      ].each_with_index do |testcase,ndx|
        specify "for #{testcase[0]}" do
          search = Customer.partial_name_matches(testcase[0]).to_a.map { |c| @c.index(c) }
          expected = testcase[1]
          expect(search.sort).to eq(expected.sort)
        end
      end
    end

  end
end
