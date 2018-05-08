require 'rails_helper'

describe 'scoping Customers' do
  before :each do
    @c1 = create(:customer)
    @c2 = create(:customer)
  end
  describe 'who have' do
    before :each do
      # customer @c1 has only seen show @s1, @c2 has only seen show @s2
      sd1 = create(:showdate, :date => Time.now)
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
        Customer.seen_any_of(@s1).should include(@c1)
      end
      it 'should exclude customer who has not seen it' do
        Customer.seen_any_of(@s1).should_not include(@c2)
      end
      it 'should select customers who have seen union of shows' do
        c = Customer.seen_any_of([@s1,@s2])
        c.should include(@c1)
        c.should include(@c2)
      end
      it 'should not select a customer who has seen nothing' do
        Customer.seen_any_of([@s1,@s2]).should_not include(@new)
      end
    end
    context 'when selecting based on NOT having seen a show' do
      it 'should select customer who has not seen it' do
        Customer.seen_none_of(@s1).should include(@c2)
      end
      it 'should exclude customer who HAS seen it' do
        Customer.seen_none_of(@s1).should_not include(@c1)
      end
      it 'should include customer who has seen nothing' do
        Customer.seen_none_of([@s1,@s2]).should include(@new)
      end
      it 'should include customer who has given donation but not seen show' do
        create(:order, :customer => @new, :contains_donation => true).finalize!
        Customer.seen_none_of([@s1,@s2]).should include(@new)
      end
      it 'should exclude customers who have seen anything in union of shows' do
        c = Customer.seen_none_of([@s1,@s2])
        c.should_not include(@c1)
        c.should_not include(@c2)
      end
    end
    it 'should select zero customers if conditions are contradictory' do
      intersection = (Customer.seen_any_of([@s1,@s2]) & Customer.seen_none_of([@s1,@s2]))
      intersection.should be_empty
    end
  end
  describe 'based on purchases' do
    before :each do
      @show_voucher_1 = create(:subscriber_voucher, :customer => @c1)
      @vid1 = @show_voucher_1.vouchertype.id
      @sub_1 = create(:bundle_voucher, :customer => @c1, :subscription => true,
        :season => 2012, :including => {@show_voucher_1 => 1})
      
      @show_voucher_2 = create(:subscriber_voucher, :customer => @c2)
      @vid2 = @show_voucher_2.vouchertype.id
      @sub_2 = create(:bundle_voucher, :customer => @c2, :subscription => true,
        :season => 2013, :including => {@show_voucher_2 => 1})

    end
    context 'of subscription' do
      it 'should identify subscribers during a given year' do
        Customer.subscriber_during(2012).should include(@c1)
      end
      it 'should exclude customers who did not subscribe that year' do
        Customer.subscriber_during(2012).should_not include(@c2)
      end
      it 'should identify subscribers given a range of years' do
        c = Customer.subscriber_during([2012, 2013])
        c.should include(@c1)
        c.should include(@c2)
      end
      it 'should compute difference-sets' do
        c = Customer.subscriber_during([2012,2013]) - Customer.subscriber_during(2012)
        c.should include(@c2)
        c.should_not include(@c1)
      end
    end
    context 'including specific Vouchertypes' do
      it 'should include customers who have purchased ANY of...' do
        c = Customer.purchased_any_vouchertypes([@vid1, @vid2])
        c.should include(@c1)
        c.should include(@c2)
      end
    end
    context 'excluding specific Vouchertypes' do
      it 'should include customers who have purchased nothing' do
        @c3 = create(:customer)
        Customer.purchased_no_vouchertypes(@vid1).should include(@c3)
      end
      it 'should include customers who have not purchased that Vouchertype' do
        Customer.purchased_no_vouchertypes(@vid2).should include(@c1)
      end
      it 'should exclude customers who have purchased ANY of that Vouchertype' do
        Customer.purchased_no_vouchertypes(@vid2).should_not include(@c2)
      end
      it 'should exclude union of customers who have purchased ANY of that Vouchertype' do
        c = Customer.purchased_no_vouchertypes([@vid1,@vid2])
        c.should_not include(@c1)
        c.should_not include(@c2)
      end
    end
  end
end
