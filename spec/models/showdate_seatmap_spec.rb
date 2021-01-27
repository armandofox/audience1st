require 'rails_helper'

describe Showdate do
  describe "when changing seatmap fails" do
    before(:each) do
      @s = create(:reserved_seating_showdate)
      @v1 = create(:revenue_voucher, :showdate => @s, :seat => 'A1')
      @v2 = create(:revenue_voucher, :showdate => @s, :seat => 'B1')
      allow(@s.seatmap).to receive(:cannot_accommodate).and_return([@v2])
    end
    it 'is not valid' do
      expect(@s).not_to be_valid
    end
    it 'lists customers who need accommodating' do
      @s.valid?
      expect(@s.errors[:base]).to include_match_for('(B1)')
    end
    it 'forbids changing to general admission' do
      @s.seatmap = nil
      expect(@s).not_to be_valid
      expect(@s.errors[:base]).to include_match_for /Cannot change performance/
    end
    it 'allows changing if no reservations' do
      @v1.destroy
      @v2.destroy
      @s.seatmap = nil
      expect(@s).to be_valid
    end
  end


  describe 'reserved-seating showdate' do
    before(:each) do
      @showdate = create(:reserved_seating_showdate) # has seats: A1,A2,B1,B2
      @seats = %w(A1 A2 B1 B2)
    end
    it 'has no occupied seats initially' do
      expect(@showdate.occupied_seats).to be_empty
    end
    context 'shows seat' do
      before(:each) do
        @v1 = create(:revenue_voucher, :showdate => @showdate, :seat => 'B1')
        @v2 = create(:revenue_voucher, :showdate => @showdate, :seat => 'B2')
        expect(@v1.showdate).to eq(@showdate)
      end
      specify 'as occupied even if sale is in progress' do
        expect(@showdate.occupied_seats).to eq %w(B1 B2)
      end
      specify 'as occupied once sale is complete' do
        @v1.update_attributes!(:finalized => true)
        expect(@showdate.occupied_seats).to eq %w(B1 B2)
      end
      specify 'as free if voucher is canceled' do
        @v2.cancel!(build(:customer))
        expect(@showdate.occupied_seats).to eq %w(B1)
      end
      specify 'if reservation is canceled and voucher left open' do
        expect { @v1.unreserve }.to change { @showdate.total_seats_left }.by(1)
        expect(@showdate.occupied_seats).to eq %w(B2)
        expect(@v1.seat).to be_blank
      end
      it 'fails to reserve occupied seat' do
        @v3 = build(:revenue_voucher, :showdate => @showdate, :seat => 'B1')
        expect(@v3).to_not be_valid
        expect(@v3.errors.full_messages).to include_match_for(/B1 is already taken/)
      end
      it 'fails to reserve nonexistent seat' do
        @v3 = build(:revenue_voucher, :showdate => @showdate, :seat => 'K1')
        expect(@v3).to_not be_valid
        expect(@v3.errors.full_messages).to include_match_for(/does not exist for this performance/)
      end
    end
  end
end
