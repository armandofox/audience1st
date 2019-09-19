require 'rails_helper'

describe Seatmap, focus: true do
  describe 'JSON' do
    before(:each) do
      @sd = create(:showdate, :seatmap => (@s = create(:seatmap)))
      @unavailable = ['A1', 'B2']
      allow(@sd).to receive(:occupied_seats).and_return(@unavailable)
    end
    it 'includes unavailable seats if called for a showdate' do
      res = Seatmap.seatmap_and_unavailable_seats_as_json(@sd)
      expect(res).to include_json(
        map: ['r[A1, ]_r[A2, ]_', '_a[B1, ]_r[B2, ]'],
        unavailable: %w(A1 B2),
        image_url: @s.image_url,
        seats: {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}
        )
    end
    it 'includes empty list of unavailable seats if called for preview' do
      res = @s.emit_json
      expect(res).to include_json(
        unavailable: [],
        image_url: @s.image_url,
        seats: {'r' => {'classes' => 'regular'}, 'a' => {'classes' => 'accessible'}}
        )
    end
  end
  describe 'valid seatmap' do
    it 'has no duplicate seats' do
      s = build(:seatmap, :csv => "A1,A2,A1,B1+,B1\r\n")
      s.parse_csv
      expect(s).not_to be_valid
      expect(s.errors.full_messages).to include("Seatmap contains duplicate seats: A1, B1")
    end
  end
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
