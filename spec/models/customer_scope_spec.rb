require 'rails_helper'

describe 'scoping Customers' do
  describe 'who have' do
    before :each do
      @c1 = create(:customer)
      @c2 = create(:customer)
      # customer @c1 has only seen show @s1, @c2 has only seen show @s2
      sd1 = create(:showdate, :date => Time.current)
      sd2 = create(:showdate, :date => 1.day.from_now)
      @s1 = sd1.show_id
      @s2 = sd2.show_id
      create(:revenue_voucher, :showdate => sd1, :customer => @c1)
      create(:revenue_voucher, :showdate => sd2, :customer => @c2)
      # customer @new has seen nothing
      @new = create(:customer)
    end
    context 'seen a show' do
      it 'should select customer who has seen it' do
        expect(Customer.seen_any_of(@s1)).to include(@c1)
      end
      it 'should exclude customer who has not seen it' do
        expect(Customer.seen_any_of(@s1)).not_to include(@c2)
      end
      it 'should select customers who have seen union of shows' do
        c = Customer.seen_any_of([@s1,@s2])
        expect(c).to include(@c1)
        expect(c).to include(@c2)
      end
      it 'should not select a customer who has seen nothing' do
        expect(Customer.seen_any_of([@s1,@s2])).not_to include(@new)
      end
    end
    context 'when selecting based on NOT having seen a show' do
      it 'should select customer who has not seen it' do
        expect(Customer.seen_none_of(@s1)).to include(@c2)
      end
      it 'should exclude customer who HAS seen it' do
        expect(Customer.seen_none_of(@s1)).not_to include(@c1)
      end
      it 'should include customer who has seen nothing' do
        expect(Customer.seen_none_of([@s1,@s2])).to include(@new)
      end
      it 'should include customer who has given donation but not seen show' do
        create(:order, :customer => @new, :contains_donation => true).finalize!
        expect(Customer.seen_none_of([@s1,@s2])).to include(@new)
      end
      it 'should exclude customers who have seen anything in union of shows' do
        c = Customer.seen_none_of([@s1,@s2])
        expect(c).not_to include(@c1)
        expect(c).not_to include(@c2)
      end
    end
    it 'should select zero customers if conditions are contradictory' do
      intersection = (Customer.seen_any_of([@s1,@s2]) & Customer.seen_none_of([@s1,@s2]))
      expect(intersection).to be_empty
    end
  end
  describe 'based on purchases' do
    before :each do
      @c1 = create(:customer)
      @c2 = create(:customer)
      @show_voucher_1 = create(:subscriber_voucher, :customer => @c1)
      @vid1 = @show_voucher_1.vouchertype.id
      @sub_1 = create(:bundle_voucher, :customer => @c1, :subscription => true,
        :season => 2012, :including => {@show_voucher_1 => 1})
      
      @show_voucher_2 = create(:subscriber_voucher, :customer => @c2)
      @vid2 = @show_voucher_2.vouchertype.id
      @sub_2 = create(:bundle_voucher, :customer => @c2, :subscription => true,
        :season => 2013, :including => {@show_voucher_2 => 1})

      # also create a couple of random other nonsubscription-type vouchers for
      # them to buy, to ensure the query logic isn't tripped up by that case
      vt_2012 = create(:revenue_vouchertype, :season => 2012)
      create(:revenue_voucher, :customer => @c1, :vouchertype => vt_2012)
      vt_2013 = create(:revenue_vouchertype, :season => 2013)
      create(:revenue_voucher, :customer => @c2, :vouchertype => vt_2013)
    end
    context 'of subscription' do
      it 'should identify subscribers during a given year' do
        expect(Customer.subscriber_during(2012)).to include(@c1)
      end
      it 'should exclude customers who did not subscribe that year' do
        expect(Customer.subscriber_during(2012)).not_to include(@c2)
      end
      it 'should identify subscribers given a range of years' do
        c = Customer.subscriber_during([2012, 2013])
        expect(c).to include(@c1)
        expect(c).to include(@c2)
      end
      it 'should compute difference-sets' do
        c = Customer.subscriber_during([2012,2013]) - Customer.subscriber_during(2012)
        expect(c).to include(@c2)
        expect(c).not_to include(@c1)
      end
      describe 'identifying nonsubscribers' do
        before :each do
          @non_2012 = Customer.nonsubscriber_during(2012)
          @non_2013 = Customer.nonsubscriber_during(2013)
        end
        specify 'excludes subscribers' do
          expect(@non_2012).not_to include(@c1)
          expect(@non_2013).not_to include(@c2)
        end
        specify 'includes everyone else' do
          expect(@non_2012.size).to eq(Customer.count - 1)
          expect(@non_2013.size).to eq(Customer.count - 1)
        end
        specify 'specifically, nonsubscribers' do
          expect(@non_2012).to include(@c2)
          expect(@non_2013).to include(@c1)
        end
        it 'should identify nonsubscribers across range of years' do
          expect(Customer.nonsubscriber_during([2012,2013]).size).
            to eq(Customer.count - 2)
        end
      end
      describe 'count of subscribers + nonsubscribers = everyone' do
        specify 'in a given year' do
          expect(Customer.subscriber_during(2013).size +
            Customer.nonsubscriber_during(2013).size).
            to eq(Customer.count)
          expect(Customer.subscriber_during(2012).size +
            Customer.nonsubscriber_during(2012).size).
            to eq(Customer.count)
        end
        specify 'across years' do
          years = (2010..2014).to_a
          expect(Customer.subscriber_during(years).size +
            Customer.nonsubscriber_during(years).size).
            to eq(Customer.count)
        end
      end
    end
    context 'including specific Vouchertypes' do
      it 'should include customers who have purchased ANY of...' do
        c = Customer.purchased_any_vouchertypes([@vid1, @vid2])
        expect(c).to include(@c1)
        expect(c).to include(@c2)
      end
    end
    context 'excluding specific Vouchertypes' do
      it 'should include customers who have purchased nothing' do
        @c3 = create(:customer)
        expect(Customer.purchased_no_vouchertypes(@vid1)).to include(@c3)
      end
      it 'should include customers who have not purchased that Vouchertype' do
        expect(Customer.purchased_no_vouchertypes(@vid2)).to include(@c1)
      end
      it 'should exclude customers who have purchased ANY of that Vouchertype' do
        expect(Customer.purchased_no_vouchertypes(@vid2)).not_to include(@c2)
      end
      it 'should exclude union of customers who have purchased ANY of that Vouchertype' do
        c = Customer.purchased_no_vouchertypes([@vid1,@vid2])
        expect(c).not_to include(@c1)
        expect(c).not_to include(@c2)
      end
    end
  end
  describe 'correct joins' do
    before(:each) do
      @v0 = create(:revenue_vouchertype).id
      @v1 = create(:revenue_vouchertype).id
      @v2 = create(:revenue_vouchertype).id
      @v3 = create(:revenue_vouchertype).id
      @v4 = create(:revenue_vouchertype).id
      @u0 = create(:customer)
      @u1 = create(:customer)
      @u2 = create(:customer)
      @u3 = create(:customer)
      # u0 has v0 only
      create(:revenue_voucher, vouchertype_id: @v0, customer: @u0)
      # u1 has v1 only
      create(:revenue_voucher, vouchertype_id: @v1, customer: @u1)
      # u2 has v0 and v1
      create(:revenue_voucher, vouchertype_id: @v1, customer: @u2)
      create(:revenue_voucher, vouchertype_id: @v0, customer: @u2)
      # u3 has neither v0 nor v1
      create(:revenue_voucher, vouchertype_id: @v2, customer: @u3)
      # everyone has purchased v4
      [@u0,@u1,@u2,@u3].each { |u| create(:revenue_voucher, vouchertype_id: @v4, customer: u) }
    end
    specify 'only u3 has purchased neither v0 nor v1' do
      u = Customer.purchased_no_vouchertypes([@v0,@v1])
      expect(u).to include(@u3)
      [@u0,@u1,@u2].each { |user| expect(u).not_to include(user) }
    end
    specify 'nobody has purchased v3' do
      [@u0,@u1,@u2,@u3].each { |u| expect(Customer.purchased_no_vouchertypes([@v3])).to include(u) }
    end
    specify 'everyone has purchased v4' do
      [@u0,@u1,@u2,@u3].each { |u| expect(Customer.purchased_no_vouchertypes([@v4])).not_to include(u) }
    end
  end
end
