require 'rails_helper'

describe GenerateRefundItem, focus:true do

  before(:each) do
    @cases = [
      [ %q{[CANCELED Super Administrator October 20, 2019 18:43] 35.00 General (Rent, the musical with the [includes brackets] 61 character name - Friday, Oct 11, 8:00 PM) [1763]},
        35.00,
        'Super Administrator October 20, 2019 18:43',
        'General (Rent, the musical with the [includes brackets] 61 character name - Friday, Oct 11, 8:00 PM)'],
      [ %q{[CANCELED JohnF May 1, 2020 18:00] 25.00 History Fund donation [999]},
        25.00, 'JohnF May 1, 2020 18:00', 'History Fund donation' ],
      [ %q{[CANCELED A F Jan 1, 2020 0:00] 0.00 T-shirt [large] [111]},
        0.0, 'A F Jan 1, 2020 0:00', 'T-shirt [large]' ]
    ]
  end
  it 'parses' do
    @cases.each do |c|
      p = GenerateRefundItem::Parser.new(c[0])
      expect(p.orig_price).to eq(c[1])
      expect(p.who_when).to eq(c[2])
      expect(p.desc).to eq(c[3])
    end
  end
  describe 'migrator' do
  end
end
