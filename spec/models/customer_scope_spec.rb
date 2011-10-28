require 'spec_helper'

describe 'scoping Customers' do
  before :each do
    @c1 = BasicModels.create_generic_customer
    @c2 = BasicModels.create_generic_customer
  end
  describe 'based on purchases' do
    before :each do
      @vt1 = BasicModels.create_subscriber_vouchertype(:season => 2012)
      @v1 = @vt1.vouchers.create
      @vt2 = BasicModels.create_subscriber_vouchertype(:season => 2013)
      @v2 = @vt2.vouchers.create
      @c1.vouchers << @v1
      @c2.vouchers << @v2
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
        c = Customer.purchased_any_vouchertypes([@vt1.id, @vt2.id])
        c.should include(@c1)
        c.should include(@c2)
      end
    end
    context 'excluding specific Vouchertypes' do
      it 'should include customers who have purchased nothing' do
        @c3 = BasicModels.create_generic_customer
        Customer.purchased_no_vouchertypes(@vt1.id).should include(@c3)
      end
      it 'should include customers who have not purchased that Vouchertype' do
        Customer.purchased_no_vouchertypes(@vt2.id).should include(@c1)
      end
      it 'should exclude customers who have purchased ANY of that Vouchertype' do
        Customer.purchased_no_vouchertypes(@vt2.id).should_not include(@c2)
      end
      it 'should exclude union of customers who have purchased ANY of that Vouchertype' do
        c = Customer.purchased_no_vouchertypes([@vt1.id, @vt2.id])
        c.should_not include(@c1)
        c.should_not include(@c2)
      end
    end
  end
end
