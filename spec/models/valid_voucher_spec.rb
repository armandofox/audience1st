require 'spec_helper'
include BasicModels

describe ValidVoucher do
  describe "for regular voucher" do
    before :each do
      #  some Vouchertype objects for these tests
      @vt_regular = BasicModels.create_revenue_vouchertype(
        :price => 10.00,
        :offer_public => Vouchertype::ANYONE)
    end
    describe "when instantiated" do
      before(:each) do
        @customer = BasicModels.create_generic_customer
        @purch = mock_model(Purchasemethod, :purchase_medium => :cash)
        @showdate = mock_model(Showdate, :valid? => true)
        @logged_in_customer = Customer.boxoffice_daemon
        @now = @vt_regular.expiration_date - 2.months
        @comment = 'A comment'
        @valid_voucher =
          ValidVoucher.create!(:vouchertype => @vt_regular,
          :showdate => @showdate,
          :start_sales => @now - 1.month + 1.day,
          :end_sales => @now + 1.month - 1.day,
          :max_sales_for_type => 10)
      end
      context "successfully" do
        describe "instantiation", :shared => true do
          it "should return valid vouchers" do
            @vouchers.each { |v| v.should be_valid }
          end
          it "should be of the specified vouchertype" do
            @vouchers.each { |v| v.vouchertype.should == @vt_regular }
          end
          it "should include the comment" do
            @vouchers.each { |v| v.comments.to_s.should == @comment }
          end
          it "should be marked processed by the logged-in customer" do
            @vouchers.each { |v| v.processed_by.should == @logged_in_customer }
          end
          it "should belong to the showdate" do
            @valid_voucher.showdate_id.should == @showdate.id
            @vouchers.each { |v| v.showdate_id.should == @showdate.id }
          end
        end
        context "without payment" do
          before(:each) do
            @num = 3
            @vouchers =
              @valid_voucher.instantiate(@logged_in_customer,@purchasemethod,@num,@comment)
          end
          it_should_behave_like "instantiation"
          it "should instantiate but not yet save the vouchers" do
            @vouchers.each { |v| v.should be_a_new_record  }
          end
        end
      end
    end
  end

  describe "for bundle voucher" do
    before :each do
      @vt_bundle = BasicModels.create_subscriber_vouchertype(:price => 25)
    end
    it "should return all vouchers if success"
    it "should create no vouchers if any instantiation fails"
  end

  describe "seats remaining" do
    before(:each) do
      @sd = mock_model(Showdate, :saleable_seats_left => 10, :valid? => true)
      @v = ValidVoucher.create!(:showdate => @sd,
        :vouchertype => (@vt_regular = BasicModels.create_revenue_vouchertype),
        :start_sales => 3.days.ago,
        :end_sales => 1.day.from_now,
        :max_sales_for_type => 0)
    end
    it "should match showdate's saleable seats if no capacity controls" do
      @v.seats_left.should == 10
    end
    it "should respect capacity controls even if more seats remain" do
      @v.update_attribute(:max_sales_for_type, 3)
      @sd.should_receive(:sales_by_type).with(@vt_regular.id).and_return(2)
      @v.seats_left.should == 1
    end
    it "should not be confused even if capacity control already exceeded" do
      @v.update_attribute(:max_sales_for_type, 3)
      @sd.should_receive(:sales_by_type).with(@vt_regular.id).and_return(5)
      @v.seats_left.should be_zero # not negative
    end
    it "should respect overall capacity even if ticket capacity remains" do
      @v.update_attribute(:max_sales_for_type, 15)
      @sd.should_receive(:sales_by_type).with(@vt_regular.id).and_return(1)
      @v.seats_left.should == 10 # not 14
    end
    it "should respect overall capacity if show is advance-sold-out" do
      @sd.stub(:saleable_seats_left).and_return(0)
      @v.seats_left.should == 0
    end
  end

  describe "seat availability" do
    before(:each) do
      #  some Vouchertype objects for these tests
      @sd = BasicModels.create_one_showdate(2.days.from_now)
      @vt_regular = BasicModels.create_revenue_vouchertype(
        :offer_public => Vouchertype::ANYONE,
        :price => 10.00)
    end
    context "for boxoffice when advance sales have ended" do
      it "should still show seats"
    end
    context "for regular patron", :shared => true do
      describe "when advance sales have ended" do
        before(:each) do
          @sd.update_attribute(:end_advance_sales, 1.day.ago)
          @v = ValidVoucher.create!(:showdate => @sd,
            :vouchertype => @vt_regular,
            :start_sales => 3.days.ago,
            :end_sales => 1.day.from_now)
        end
        it "should be nil even if valid voucher's advance sales have not" do
          pending
        end
        it "should explain that no seats available since advance sales have ended" do
          pending
          ValidVoucher.no_seats_explanation.should match(/advance sales/i)
        end
      end
      describe "capacity-controlled seats", :shared => true  do
        before(:each) do
          @limit = 5
          @v = ValidVoucher.create!(:showdate => @sd,
            :vouchertype => @vt_regular,
            :start_sales => 3.days.ago,
            :end_sales => 1.day.from_now,
            :max_sales_for_type => @limit)
        end
        describe "when show has 5 saleable seats left" do
          before(:each) do ; @sd.stub!(:saleable_seats_left).and_return(5) ; end
          it "but capacity control of #{@limit} exhausted" do
            pending
          end
          context "but only 3 are allowed by capacity control" do
            it "should show available seats" 
            it "should show 3 available seats (not 5)" 
          end
          it "should show seats available when capacity available"
        end
        context "when show has no saleable seats left" do
          it "should be empty when capacity reached"
          it "should be empty when capacity not reached"
        end
      end
      describe "promo-code-protected seats", :shared => true do
      end
      describe "non-promo-code, non-capacity-controlled seats" do
        #it_should_behave_like "capacity-controlled seats"
      end
      describe "promo-code-protected, non-cap-controlled seats" do
        #it_should_behave_like "promo-code-protected seats"
      end
      describe "promo-code-protected, capacity-controlled seats" do
        # it_should_behave_like "promo-code-protected seats"
        # it_should_behave_like "capacity-controlled seats"
      end
    end
    context "for subscriber" do
      before(:each) do
        @u = mock_model(Customer, :is_boxoffice => false, :is_subscriber? => true)
      end
      it_should_behave_like "for regular patron"
    end
    context "for nonsubscriber" do
      before(:each) do
        @u = mock_model(Customer, :is_boxoffice => false, :is_subscriber? => nil)
      end
      it_should_behave_like "for regular patron"
    end
  end
  describe "promo code filtering" do
    before(:each) do
      @v = ValidVoucher.new
    end
    context "with no promo-code" do
      before(:each) do
        @v.promo_code = nil
      end
      it "should succeed if promo_code is blank and promo code is empty string" do
        @v.promo_code_matches(nil).should be_true
      end
      it "should succeed if promo_code is blank and promo code is not" do
        @v.promo_code_matches('foo!').should be_true
      end
      it "should succeed if promo code is nil (not empty)" do
        @v.promo_code_matches(nil).should be_true
      end
    end
    describe "with nonblank", :shared => true do
      it "should succeed if promo_code matches exactly" do
        @v.promo_code_matches('foo').should be_true
      end
      it "should match case-insensitively" do
        @v.promo_code_matches('FoO').should be_true
      end
      it "should succeed if supplied promo_code is not blank-stripped" do
        @v.promo_code_matches(' Foo ').should be_true
      end
      it "should fail if only partial word match" do
        @v.promo_code_matches('fo').should be_false
      end
    end
    context "with a single promo_code" do
      before(:each) do ; @v.promo_code = 'foo' ; end
      it_should_behave_like "with nonblank"
    end
    context "with multiple promo_codes" do
      before(:each) do ; @v.promo_code = 'bAr,Foo,BAZ' ; end
      it_should_behave_like "with nonblank"
    end
  end
end
