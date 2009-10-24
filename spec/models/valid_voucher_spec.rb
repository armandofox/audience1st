require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ValidVoucher do

  before :all do
    #  some Vouchertype objects for these tests
    @vt_regular = Vouchertype.create!(:fulfillment_needed => false,
                                      :name => 'regular voucher',
                                      :category => 'revenue',
                                      :account_code => '9999',
                                      :price => 10.00,
                                      :valid_date => Time.now - 1.month,
                                      :expiration_date => Time.now+1.month)
    @vt_bundle = Vouchertype.create!(:fulfillment_needed => false,
                                     :name => 'bundle voucher',
                                     :category => 'bundle',
                                     :price => 25.00,
                                     :account_code => '8888',
                                     :valid_date => Time.now - 1.month,
                                     :expiration_date => Time.now+1.month)
  end

  describe "when instantiated for a customer and showdate" do
    before(:each) do
      @showdate = mock_model(Showdate, :valid? => true)
      @logged_in_customer = Customer.boxoffice_daemon
      @purchasemethod = mock_model(Purchasemethod)
      @valid_voucher =
        ValidVoucher.create!(:vouchertype => @vt_regular,
                             :showdate => @showdate,
                             :max_sales_for_type => 100)
      @num = 3
      @vouchers =
        @valid_voucher.instantiate!(@logged_in_customer,@purchasemethod,@num)
    end
#     it "should belong to the customer" do
#       @owning_customer.should have(@num).vouchers
#       @owning_customer.vouchers.each do |v|
#         v.should be_an_instance_of(Voucher)
#       end
#     end
    it "should be of the specified vouchertype" do
      @vouchers.each do |v|
        v.vouchertype.should == @vt_regular
      end
    end
    it "should be marked processed by the logged-in customer" do
      @vouchers.each do |v|
        v.processed_by.should == @logged_in_customer
      end
    end
    it "should belong to the showdate" do
      @vouchers.each do |v|
        v.showdate_id.should == @showdate.id
      end
    end
  end

end
