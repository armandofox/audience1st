require 'rails_helper'

describe Seatmap do
  describe 'JSON' do
    before(:each) do
      @sd = create(:reserved_seating_showdate)
      @s = @sd.seatmap
      @unavailable = ['A1', 'B2']
      allow(@sd).to receive(:occupied_seats).and_return(@unavailable)
    end
    it 'includes unavailable seats if called for a showdate' do
      res = Seatmap.seatmap_and_unavailable_seats_as_json(@sd)
      expect(res).to include_json(
        map: ['r[Reserved A1, ]_r[Reserved A2, ]_', '_a[Reserved B1, ]_r[Reserved B2, ]'],
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
    describe 'has no duplicate seats' do
      specify 'in same zone' do
        s = build(:seatmap, :csv => "res:A1,res:A2,res:A1,res:B1+,res:B1\r\n")
        expect(s).not_to be_valid
        expect(s.errors.full_messages).to include("Seatmap contains duplicate seats: A1, B1")
      end
      specify 'in different zones' do
        SeatingZone.create!(:short_name => 'p', :name => 'Premium')
        s = build(:seatmap, :csv => "res:A1,res:A2,p:A1,res:B1+,p:B1\r\n")
        expect(s).not_to be_valid
        expect(s.errors.full_messages).to include("Seatmap contains duplicate seats: A1, B1")
      end
    end
    it 'parses zones' do
      3.times { create(:seating_zone) } # z1, z2, z3
      s = build(:seatmap, :csv => "z1:A1,z2:A2,z3:B3,z3:C4+,z1:D5")
      expect(s).to be_valid
      expect(s.zones['z1'].sort).to eq %w(A1 D5)
      expect(s.zones['z2'].sort).to eq %w(A2)
      expect(s.zones['z3'].sort).to eq %w(B3 C4)
    end
    it 'uses only existing zones' do
      s = build(:seatmap, :csv => "res:A1,p:A2\r\n")
      expect(s).not_to be_valid
      expect(s.errors.full_messages).to include("No seating zone with short name 'p' exists")
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
  describe 'checking availability of reserved seats' do
    before(:each) do
      @s = create(:seatmap)     # with seats A1,A2,B1,B2
    end
    def create_vouchers(seat_list)
      s = Showdate.first || create(:showdate)
      vouchers = seat_list.map do |seat|
        create(:revenue_voucher, :showdate => s, :seat => seat)
      end
    end
    context 'is empty' do
      specify 'when seats match exactly' do
        v = create_vouchers %w(A2 B1 B2 A1)
        expect(@s.cannot_accommodate(v)).to be_empty
      end
      specify 'when no seats specified' do
        v = create_vouchers(['','',''])
        expect(@s.cannot_accommodate(v)).to be_empty
      end
    end
    context 'is nonempty' do
      specify 'when 1 seat is unavailable even if others blank' do
        v = create_vouchers(['','A1','B1','C1'])
        list = @s.cannot_accommodate(v)
        expect(list.size).to eq(1)
        expect(list.first.seat).to eq('C1')
      end
    end
  end
end
