require 'spec_helper'
include BasicModels

describe ValidVoucher do
  describe 'instantiation' do
    before(:each) do
      @vt_regular = BasicModels.create_revenue_vouchertype
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
    describe 'of a non-bundle voucher' do
      context "successfully" do
        before(:each) do
          @vouchers =
            @valid_voucher.instantiate(@logged_in_customer,@purchasemethod,3,@comment)
        end
        it 'should have 3 vouchers' do ; @vouchers.length.should == 3 ; end
        it "should return valid vouchers" do ;@vouchers.each { |v| v.should be_valid } ; end
        it "should include the comment" do ; @vouchers.each { |v| v.comments.to_s.should == @comment } ; end
        it "should be marked processed by the logged-in customer" do
            @vouchers.each { |v| v.processed_by.should == @logged_in_customer }
        end
        it "should belong to the showdate" do
          @valid_voucher.showdate_id.should == @showdate.id
          @vouchers.each { |v| v.showdate_id.should == @showdate.id }
        end
        it "should not save the vouchers" do ; @vouchers.each { |v| v.should be_a_new_record  } ; end
      end
    end
    describe 'of a bundle voucher' do
      before :each do
        @vt_bundle = BasicModels.create_subscriber_vouchertype(:price => 25)
      end
      it 'should instantiate individual vouchers in bundle' do
        pending 'Refactoring of subscription sales using valid-vouchers'
      end
    end
  end

  describe 'adjusting' do
    before :each do
      @vv = ValidVoucher.new(
        :vouchertype => mock_model(Vouchertype, :visible_to => true, :offer_public_as_string => 'NOT-YOU')
        )
    end
    shared_examples_for 'for regular customer' do
      context 'for reasons based on visibility' do
        subject do
          c = mock_model(Customer)
          @vv.stub!(:visible_to).with(c).and_return(visible)
          the_showdate.stub(:saleable_seats_left).and_return(10)
          @vv.showdate = the_showdate
          @vv.adjust_for_customer(c)
        end
        shared_examples_for 'invisible' do
          it { should_not be_visible }
          its(:max_sales_for_type) { should be_zero }
        end
        context 'when vouchertype not visible to customer' do
          let(:visible) { false }
          let(:the_showdate) { mock_model Showdate, :thedate => 1.day.from_now }
          it_should_behave_like 'invisible'
          its(:explanation) { should == 'Ticket sales of this type restricted to NOT-YOU' }
        end
        context 'when showdate is in the past' do
          let(:visible) { true }
          let(:the_showdate) { mock_model(Showdate, :thedate => 1.day.ago) }
          it_should_behave_like 'invisible'
          its(:explanation) { should == 'Event date is in the past' }
        end
        context "when showdate's advance sales have ended" do
          let(:visible) { true }
          let(:the_showdate) { mock_model(Showdate, :thedate => 1.day.from_now, :end_advance_sales => 1.day.ago) }
          its(:explanation) { should == 'Advance sales for this event are closed' }
        end
      end
      context 'when performance is sold out' 
      context 'for reasons based on valid-voucher properties' do
        @vv
      end
    end
    describe 'when promo code is required but not given' do
      subject do
        @vv.stub!(:promo_code_matches).and_return(false)
        @vv.adjust_for_customer(mock_model(Customer))
      end
      it { should_not be_visible }
      its(:max_sales_for_type) { should be_zero }
      its(:explanation)        { should == 'Promo code required' }
    end
    describe 'when correct promo code is provided' do
      before :each do ; @vv.stub!(:promo_code_matches).and_return(true) ; end
      it_should_behave_like 'for regular customer'
    end
  end

  describe "seats remaining" do
    subject do
      ValidVoucher.new(
        :showdate => mock_model(Showdate, :valid? => true,
          :saleable_seats_left => showdate_seats,
          :sales_by_type => existing_sales),
        :vouchertype => mock_model(Vouchertype),
        :start_sales => 3.days.ago,
        :end_sales => 1.day.from_now,
        :max_sales_for_type => capacity_control)
    end
    context "without capacity controls should match showdate's saleable seats" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 0 }
      let(:existing_sales)   { 10 }
      its(:seats_remaining)  { should == 10 }
    end
    context "should respect capacity controls even if more seats remain" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 3 } 
      let(:existing_sales)   { 2 } 
      its(:seats_remaining)  { should == 1 }
    end
    context "should be zero (not negative) even if capacity control already exceeded" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 3  }
      let(:existing_sales)   { 5  }
      its(:seats_remaining)  { should be_zero }
    end
    context "should respect overall capacity even if ticket capacity remains" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 15 }
      let(:existing_sales)   { 1  }
      its(:seats_remaining)  { should == 10 }
    end
    context "should respect overall capacity if show is advance-sold-out" do
      let(:showdate_seats)   { 0  }
      let(:capacity_control) { 0  }
      let(:existing_sales)   { 10 }
      its(:seats_remaining)  { should be_zero }
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
    describe 'for nonsubscriber' do
      
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
    before :all do ; ValidVoucher.send(:public, :promo_code_matches) ; end
    after :all do ; ValidVoucher.send(:private, :promo_code_matches) ; end
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
