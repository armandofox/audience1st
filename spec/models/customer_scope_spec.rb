require 'spec_helper'

describe 'scoping Customers' do
  before :each do
    @c1 = BasicModels.create_generic_customer
    @c2 = BasicModels.create_generic_customer
  end
  describe 'to subscriber' do
    before :each do
      @v1 = BasicModels.create_subscriber_vouchertype(:season => 2012).vouchers.create
      @v2 = BasicModels.create_subscriber_vouchertype(:season => 2013).vouchers.create
      @c1.vouchers << @v1
      @c2.vouchers << @v2
    end
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
end
