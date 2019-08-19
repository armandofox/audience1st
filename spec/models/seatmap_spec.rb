require 'rails_helper'

describe Seatmap do
  describe 'seat existence' do
    before(:each) do ; @s = create(:seatmap) ; end # has seats A1,B1,A2,B2
    specify 'for existing seat' do
      expect(@s.includes_seat?('B1')).to be_truthy
    end
    specify 'for nonexistent near-match' do
      expect(@s.includes_seat?('B')).to be_falsy
    end
    specify 'case mismatch' do
      expect(@s.includes_seat?('b1')).to be_falsy
    end
    specify 'exhaustively' do
      %w(A1 B2 A2 B1).each { |s| expect(@s.includes_seat?(s)).to be_truthy }
    end
  end
end
