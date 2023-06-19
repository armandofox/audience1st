require 'rails_helper'

describe 'ValidVoucher adjusting' do
  shared_examples_for 'visible, zero capacity' do
    it { is_expected.to be_visible }
    its(:explanation) { should_not be_blank }
    its(:max_sales_for_this_patron) { should be_zero }
  end
  shared_examples_for 'invisible, zero capacity' do
    it { is_expected.not_to be_visible }
    its(:explanation) { should_not be_blank }
    its(:max_sales_for_this_patron) { should be_zero }
  end

  describe 'for reservation using existing voucher' do
    context 'after deadline' do
      subject do
        s = create(:showdate, :date => 1.day.from_now, :max_advance_sales => 200)
        v = ValidVoucher.new(:showdate => s, :end_sales => 1.day.ago, :max_sales_for_type => 100)
        v.adjust_for_customer_reservation
      end
      its(:explanation) { should == 'Advance reservations for this performance are closed' }
      its(:max_sales_for_this_patron) { should be_zero }
    end
    context 'when valid' do
      subject do
        s = create(:showdate, :date => 1.day.from_now)
        v = ValidVoucher.new(:showdate => s, :end_sales => 1.day.from_now, :max_sales_for_type => 10)
        v.adjust_for_customer_reservation
      end
      its(:max_sales_for_this_patron) { should == 10 }
      its(:explanation) { should == '10 remaining' }
    end
  end

  describe 'for visibility' do
    before :all do ; ValidVoucher.send(:public, :adjust_for_visibility) ; end
    subject do
      v = ValidVoucher.new
      allow(v).to receive(:match_promo_code).and_return(promo_matched)
      allow(v).to receive(:visible_to?).and_return(visible_to_customer)
      allow(v).to receive(:offer_public_as_string).and_return('NOT YOU')
      v.adjust_for_visibility
      v
    end
    describe 'when promo code mismatch' do
      let(:promo_matched)    { nil }
      let(:visible_to_customer) { true }
      it_should_behave_like 'invisible, zero capacity'
      its(:explanation) { should == 'Promo code  required' }
    end
    describe 'when invisible to customer' do
      let(:promo_matched)       { true }
      let(:visible_to_customer) { nil }
      it_should_behave_like 'invisible, zero capacity'
      its(:explanation) { should == 'Ticket sales of this type restricted to NOT YOU' }
    end
    describe 'when promo code matches and visible to customer' do
      let(:promo_matched)       { true }
      let(:visible_to_customer) { true }
      its(:explanation) { should be_blank }
    end
  end
  describe 'for showdate' do
    before :all do ; ValidVoucher.send(:public, :adjust_for_showdate) ; end
    subject do
      v = ValidVoucher.new(:showdate => the_showdate)
      v.adjust_for_showdate
      v
    end
    describe 'that is sold out' do
      let(:the_showdate) { mock_model(Showdate, :thedate => 1.day.from_now, :saleable_seats_left => 0, :sold_out? => true) }
      it_should_behave_like 'visible, zero capacity'
      its(:explanation) { should == 'Event is sold out' }
    end
  end

  describe 'for per-ticket-type sales dates' do
    before :all do ; ValidVoucher.send(:public, :adjust_for_sales_dates) ; end
    subject do
      v = ValidVoucher.new(:start_sales => starts, :end_sales => ends, :showdate => create(:showdate))
      v.adjust_for_sales_dates
      v
    end
    describe 'before start of sales' do
      let(:starts) { @time = 2.days.from_now }
      let(:ends)   { 3.days.from_now }
      it_should_behave_like 'visible, zero capacity'
      its(:explanation) { should == "Tickets of this type not on sale until #{@time.to_formatted_s(:showtime)}" }
    end
    describe 'after end of sales' do
      let(:starts) { 2.days.ago }
      let(:ends)   { @time = 1.day.ago }
      it_should_behave_like 'visible, zero capacity'
      its(:explanation) { should == "Tickets of this type not sold after #{@time.to_formatted_s(:showtime)}" }
    end
    describe 'when neither condition applies' do
      let(:starts) { 2.days.ago }
      let(:ends)   { 1.day.from_now }
      its(:explanation) { should be_blank }
    end
  end

  describe 'for capacity' do
    before :all do ; ValidVoucher.send(:public, :adjust_for_capacity) ; end
    subject do
      v = ValidVoucher.new(:showdate => create(:showdate))
      allow(v).to receive(:seats_of_type_remaining).and_return(seats)
      v.adjust_for_capacity
      v
    end
    describe 'when zero seats remain' do
      let(:seats) { 0 }
      its(:max_sales_for_this_patron) { should be_zero }
      its(:explanation) { should == 'No seats remaining for tickets of this type' }
    end
    describe 'when one or more seats remain' do
      let(:seats) { 5 }
      its(:max_sales_for_this_patron) { should == 5 }
      its(:explanation) { should == '5 remaining' }
    end
  end

  describe 'seats of type remaining' do
    before(:each) do
      z1 = (s1 = FactoryBot.create(:seating_zone)).short_name
      z2 = (s2 = FactoryBot.create(:seating_zone)).short_name
      @sm = create(:seatmap, :csv => "#{z1}:A1,,#{z2}:A2\r\n,#{z1}:B1+,,#{z2}:B2\r\n")
      @showdate = create(:reserved_seating_showdate, :sm => @sm)
      @vv1 = create(:valid_voucher,
                    :showdate => @showdate,
                    :vouchertype => create(:revenue_vouchertype,
                                           :seating_zone => s1))
      @vv2 = create(:valid_voucher,
                    :showdate => @showdate,
                    :vouchertype => create(:revenue_vouchertype,
                                           :seating_zone => s2))
      # mark seats in zone z2 (A2,B2) as occupied
      allow(@showdate).to receive(:occupied_seats).and_return(['A2','B2'])
    end
    describe 'when seating zones are used' do
      specify 'shows zero seats remaining for zone-restricted vouchertype if zone sold out' do
        expect(@vv2.seats_of_type_remaining).to eq(0)
        expect(@vv1.seats_of_type_remaining).to eq(2)
      end
      specify 'and open house seats in zone, adjusts count of available seats' do
        # A2 is already occupied - designate it as a house seat.
        # A1 is NOT occupied - designate it as a house seat.
        # the number of seats in zone 1 should be 1, since [A1,B1] are free but A1 is house
        allow(@showdate).to receive(:open_house_seats).and_return(['A1'])
        expect(@vv1.seats_of_type_remaining).to eq(1)
        expect(@vv2.seats_of_type_remaining).to eq(0)
      end
      specify 'and open house seats outside of zone, does not change available seat count' do
        # A2 is an open seat outside of zone 1; designate it as a house seat.
        # this should not change the available seat count for zone 1.
        allow(@showdate).to receive(:open_house_seats).and_return(['A2'])
        expect(@vv1.seats_of_type_remaining).to eq(2)
      end
    end
    describe 'with house seats and no seating zones' do
      before(:each) do
        @vv3 = create(:valid_voucher,
                      :showdate => @showdate,
                      :vouchertype => create(:revenue_vouchertype))
      end
      it 'adjusts for open house seats' do
        allow(@showdate).to receive(:open_house_seats).and_return(['B1'])
        # B1 is an open house seat, so available seat count should be adjusted by 1 (but not by 2)
        expect(@vv1.seats_of_type_remaining).to eq(1)
      end
      it 'shows sold out if the only open seats are house seats' do
        allow(@showdate).to receive(:open_house_seats).and_return(['A1','B1'])
        expect(@vv1.seats_of_type_remaining).to eq(0)
      end
    end
  end
end
