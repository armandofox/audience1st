require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ValidVoucher do
  describe "for regular voucher" do
    before :all do
      #  some Vouchertype objects for these tests
      @vt_regular = Vouchertype.create!(:fulfillment_needed => false,
                                        :name => 'regular voucher',
                                        :category => 'revenue',
                                        :account_code => '9999',
                                        :price => 10.00,
                                        :valid_date => Time.now - 1.month,
                                        :expiration_date => Time.now+1.month)
    end
    describe "when instantiated" do
      context "successfully" do
        before :each do
          @showdate = mock_model(Showdate, :valid? => true)
          @logged_in_customer = Customer.boxoffice_daemon
          @purchasemethod = mock_model(Purchasemethod)
          @valid_voucher =
            ValidVoucher.create!(:vouchertype => @vt_regular,
            :showdate => @showdate,
            :start_sales => Time.now - 1.month + 1.day,
            :end_sales => Time.now + 1.month - 1.day,
            :max_sales_for_type => 10)
          @valid_voucher.should be_valid
          @num = 3
          @vouchers =
            @valid_voucher.instantiate(@logged_in_customer,@purchasemethod,@num)
        end
        it "should return valid vouchers" do
          @vouchers.each { |v| v.should be_valid }
        end
        it "should be of the specified vouchertype" do
          @vouchers.each { |v| v.vouchertype.should == @vt_regular }
        end
        it "should be marked processed by the logged-in customer" do
          @vouchers.each { |v| v.processed_by.should == @logged_in_customer }
        end
        it "should belong to the showdate" do
          @valid_voucher.showdate_id.should == @showdate.id
          @vouchers.each { |v| v.showdate_id.should == @showdate.id }
        end
        it "should instantiate but not yet save the vouchers" do
          @vouchers.each { |v| v.should be_a_new_record  }
        end
      end
      context "unsuccessfully" do
        it "should fail if max sales reached or exceeded"
        it "should fail if show is sold out"
      end
    end
  end

  describe "for bundle voucher" do
    before :all do
      @vt_bundle = Vouchertype.create!(:fulfillment_needed => false,
                                       :name => 'bundle voucher',
                                       :category => 'bundle',
                                       :price => 25.00,
                                       :account_code => '8888',
                                       :valid_date => Time.now - 1.month,
                                       :expiration_date => Time.now+1.month)
    end
    it "should return all vouchers if success"
    it "should create no vouchers if any instantiation fails"
  end
end
